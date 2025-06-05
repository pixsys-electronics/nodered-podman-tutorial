# Use Node-RED as base
FROM docker.io/nodered/node-red:3.1.15

# Maintainer information
LABEL maintainer="YourName <youremail@example.com>"

# Install additional modules: Dashboard, OPC-UA, InfluxDB
RUN npm install node-red-node-serialport node-red-dashboard node-red-contrib-modbus node-red-contrib-modbus-flex-server && \
    npm cache clean --force

# Expose port 1880 for Node-RED access
EXPOSE 1880
