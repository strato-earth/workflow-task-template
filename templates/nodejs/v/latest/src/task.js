export const handler = async (event, context) => {
  const runtimeEnv = process.env.RUNTIME_ENV || 'unknown';
  const msg = `Hello from ${runtimeEnv}!`;
  console.log(msg);

  // Print the received event and context
  console.log('Received event:', event);
  console.log('Received context:', context);

  const response = {
    statusCode: 200,
    body: JSON.stringify(msg),
  };

  return response;
};
