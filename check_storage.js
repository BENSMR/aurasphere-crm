// Quick verification script to check Supabase storage
import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.38.0').then(async ({ createClient }) => {
  const supabase = createClient(
    'https://igkvgrvrdpbmunxwhkax.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlna3ZncnZyZHBibXVueHdoa2F4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQyNDUyMDAsImV4cCI6MjAyMDI0NTIwMH0.LMQFPSP8JVqVdP_sKHbQWqfyV8tHzM1KI5tLQ7vPczs'
  );
  
  try {
    const { data, error } = await supabase.storage.listBuckets();
    
    console.log('=== SUPABASE STORAGE BUCKETS ===');
    console.log('');
    
    if (error) {
      console.log('❌ Error:', error.message);
    } else {
      console.log('✅ Found', data.length, 'bucket(s):');
      console.log('');
      data.forEach(bucket => {
        console.log(`  📦 Bucket: ${bucket.name}`);
        console.log(`     Public: ${bucket.public}`);
        console.log(`     Created: ${bucket.created_at}`);
        console.log('');
      });
      
      // Check for aura_backups specifically
      const hasAuraBackups = data.some(b => b.name === 'aura_backups');
      console.log(hasAuraBackups ? '✅ aura_backups bucket EXISTS' : '❌ aura_backups bucket NOT FOUND');
    }
  } catch (err) {
    console.log('❌ Error:', err.message);
  }
});
