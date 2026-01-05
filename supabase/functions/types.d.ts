// Type definitions for Deno runtime in VS Code
// This file helps VS Code understand Deno global types

declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
  serve: (handler: (req: Request) => Promise<Response>) => void;
  [key: string]: any;
};

declare interface Request {
  json(): Promise<any>;
  method: string;
  headers: Headers;
  [key: string]: any;
}

declare interface Response {
  ok: boolean;
  status: number;
  [key: string]: any;
}
