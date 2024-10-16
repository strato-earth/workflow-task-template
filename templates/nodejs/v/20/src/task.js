async function main() {
  try {
    const runtimeEnv = process.env.RUNTIME_ENV || 'unknown';
    const msg = `Hello from ${runtimeEnv}!`;
    console.log(msg);

    // Print all command-line arguments
    if (process.argv.length > 2) {
      console.log('Received the following arguments:');
      process.argv.slice(2).forEach((arg, index) => {
        console.log(`Argument ${index + 1}: ${arg}`);
      });
    } else {
      console.log('No arguments were passed.');
    }
    
    return 0;

  } catch (error) {
    console.error("Error processing environment variables:", error);
    return 1;
  }
}

process.exit(await main());
