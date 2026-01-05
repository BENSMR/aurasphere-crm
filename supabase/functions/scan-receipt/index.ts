import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { imageBase64, imageUrl } = await req.json();

    // Validate input
    if (!imageBase64 && !imageUrl) {
      return new Response(
        JSON.stringify({
          error: "Missing required field: imageBase64 or imageUrl",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get OCR API key from environment
    const ocrApiKey = Deno.env.get("OCR_API_KEY");
    if (!ocrApiKey) {
      console.error("❌ OCR_API_KEY not found in environment");
      return new Response(
        JSON.stringify({
          error: "OCR service not configured",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Prepare OCR request
    const ocrPayload: Record<string, unknown> = {
      language: "en",
      isOverlayRequired: false,
      apikey: ocrApiKey,
      filetype: "base64",
    };

    // Add image data
    if (imageBase64) {
      ocrPayload.base64Image = `data:image/jpeg;base64,${imageBase64}`;
    } else if (imageUrl) {
      ocrPayload.url = imageUrl;
      ocrPayload.filetype = "URL";
    }

    console.log("📸 Processing receipt image with OCR...");

    // Call OCR API (using OCR.space as example)
    const ocrResponse = await fetch("https://api.ocr.space/parse/image", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(ocrPayload),
    });

    if (!ocrResponse.ok) {
      console.error("❌ OCR API error:", ocrResponse.status);
      return new Response(
        JSON.stringify({
          error: "OCR processing failed",
          status: ocrResponse.status,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const ocrResult = await ocrResponse.json();

    // Check if OCR was successful
    if (!ocrResult.IsErroredOnProcessing && ocrResult.ParsedText) {
      console.log("✅ OCR processing successful");

      // Parse receipt data from OCR text
      const parsedData = parseReceiptData(ocrResult.ParsedText);

      return new Response(
        JSON.stringify({
          success: true,
          message: "Receipt scanned successfully",
          rawText: ocrResult.ParsedText,
          parsedData: parsedData,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    } else {
      console.error("❌ OCR failed to process image");
      return new Response(
        JSON.stringify({
          error: "Failed to process receipt image",
          details: ocrResult.ErrorMessage || "Unknown OCR error",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
  } catch (error) {
    console.error("❌ Scan receipt proxy error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

// Helper function to parse receipt data from OCR text
function parseReceiptData(
  text: string
): Record<string, unknown> {
  const data: Record<string, unknown> = {
    vendor: null,
    amount: null,
    date: null,
    items: [],
  };

  const lines = text.split("\n");

  // Extract amount (look for currency symbols)
  const amountMatch = text.match(/[\$£€][\d,]+\.?\d*/);
  if (amountMatch) {
    data.amount = amountMatch[0];
  }

  // Extract date (look for common date patterns)
  const dateMatch = text.match(
    /(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})|(\d{4}[-/]\d{1,2}[-/]\d{1,2})/
  );
  if (dateMatch) {
    data.date = dateMatch[0];
  }

  // First non-empty line is likely vendor name
  for (const line of lines) {
    if (line.trim().length > 0) {
      data.vendor = line.trim();
      break;
    }
  }

  // Extract items (lines with numbers that might be prices)
  for (const line of lines) {
    const itemMatch = line.match(/^(.+?)\s+[\$£€]?[\d,]+\.?\d*/);
    if (itemMatch && itemMatch[1].trim().length > 0) {
      data.items = [...(data.items as string[]), itemMatch[1].trim()];
    }
  }

  return data;
}
