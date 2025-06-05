# Use Node-RED as base
FROM nodered/node-red:latest

# Install additional modules: Dashboard, OPC-UA, InfluxDB
RUN npm install node-red-dashboard node-red-contrib-opcua node-red-contrib-influxdb && \
    npm cache clean --force

# Expose port 1880 for Node-RED access
EXPOSE 1880

# Default command to start Node-RED
CMD ["npm", "start", "--", "--userDir", "/data"]