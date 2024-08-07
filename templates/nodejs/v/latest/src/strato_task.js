// eslint-disable-next-line require-await
export const handler = async () => {
  const msg = `Hello from ${process.env.RUNTIME_ENV}!`;

  console.log(msg);
  const response = {
    statusCode: 200,
    body: JSON.stringify(msg)
  };
  return response;
};
