module.exports = {
  apps: [
    {
      name: 'priority_first_backend',
      cwd: '/home/talent/projects/priority_first/backend',
      script: 'src/main.js',
      instances: 1,
      autorestart: true,
      watch: false,
      env: {
        NODE_ENV: 'production',
        PORT: '8110'
      }
    }
  ]
};
