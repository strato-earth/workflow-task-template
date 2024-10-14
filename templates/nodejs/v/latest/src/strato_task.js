import { execSync } from 'child_process';
import fs from 'fs';
import { handler as taskHandler } from './task.js'; // Ensure correct path and export

// Export handler as an ES module export
export const handler = async (event = {}, context = {}) => {
  const preScriptPath = '/var/task/pre.sh';
  const postScriptPath = '/var/task/post.sh';
  const envFilePath = '/tmp/strato_env.json';

  try {
    if (fs.existsSync(preScriptPath)) {
      console.log('Running pre.sh...');
      fs.writeFileSync(envFilePath, JSON.stringify(event), 'utf-8');

      // Pass the event as the first argument to pre.sh
      execSync(`${preScriptPath}`, { stdio: 'inherit' });
      if (fs.existsSync(envFilePath)) {
        console.log('Loading environment variables from /tmp/strato_env.json');
        const envData = fs.readFileSync(envFilePath, 'utf-8');
        const envVars = JSON.parse(envData);

        // Set the environment variables in Node.js
        Object.keys(envVars).forEach((key) => {
          console.log(`Setting environment variable: ${key}=${envVars[key]}`);
          process.env[key] = envVars[key];
        });
      }
    } else {
      console.log('pre.sh not found, skipping.');
    }

    const response = await taskHandler(event, context); // Call the imported function

    if (fs.existsSync(postScriptPath)) {
      console.log('Running post.sh...');
      execSync(postScriptPath, { stdio: 'inherit' });
    } else {
      console.log('post.sh not found, skipping.');
    }

    return response;
  } catch (error) {
    console.error('Error occurred:', error);

    if (fs.existsSync(postScriptPath)) {
      console.log('Running post.sh...');
      execSync(postScriptPath, { stdio: 'inherit' });
    } else {
      console.log('post.sh not found, skipping.');
    }

    throw error;
  }
};
