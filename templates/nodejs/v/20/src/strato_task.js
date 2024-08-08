// src/strato_task.js
import { execSync } from 'child_process';
import fs from 'fs';
import { handler as taskHandler } from './task.js'; // Ensure correct path and export

// Export handler as an ES module export
export const handler = async (event = {}, context = {}) => {
  try {
    const preScriptPath = '/var/task/pre.sh';
    const postScriptPath = '/var/task/post.sh';

    if (fs.existsSync(preScriptPath)) {
      console.log('Running pre.sh...');
      execSync(preScriptPath, { stdio: 'inherit' });
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
    throw error;
  }
};
