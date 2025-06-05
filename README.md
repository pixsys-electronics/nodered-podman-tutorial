docker build -f docker/node-red.Dockerfile -t node-red-example .
mkdir node-red-data
docker run -it -p 1880:1880 -v $(pwd)/node-red-data:/data node-red-example:latest

# **Guide to Configuring a Podman Container with Custom Node-RED**

## **Objective**

Create a Podman container with:

- Pre-installed Node-RED
- Configured **node-red-dashboard** and **node-red-contrib-modbus** modules
- Access to `/dev/ttyUSB0` devices (for Modbus)
- Network in `host` mode
- Persistent volume to save Node-RED flows and configurations
- Start and connect to the container

---

## **Steps**

### 1. Connect to the Device and Prepare the Working Directory

1. **Connect to the device via SSH** using the **`user`** account:
   
   ```bash
   ssh user@<DEVICE_IP>
   ```

2. **Navigate to the persistent folder** `/data/user`:
   
   ```bash
   cd /data/user
   ```

3. **Create a dedicated folder** for the image and project:
   
   ```bash
   mkdir -p node-red-podman/data && cd node-red-podman
   ```

---

### 2. Create the Dockerfile

Create a file named **`node-red.Dockerfile`** with the following content:

```dockerfile
# Use Node-RED as base
FROM nodered/node-red:latest

# Maintainer information
LABEL maintainer="YourName <youremail@example.com>"

# Install additional modules: Dashboard and Modbus
RUN npm install node-red-node-serialport node-red-dashboard node-red-contrib-modbus node-red-contrib-modbus-flex-server --unsafe-perm && \
    npm cache clean --force

# Expose port 1880 for Node-RED access
EXPOSE 1880

# Default command to start Node-RED
CMD ["npm", "start", "--", "--userDir", "/data"]
```

---

### 3. Build the Custom Image

Run the following command to create the custom image:

```bash
podman build -t node-red-custom -f node-red.Dockerfile
```

---

### 4. Create the Podman Compose File

Create a file named **`podman-compose.yml`** with the following content:

```yaml
version: "3.9"

services:
  nodered:
    image: node-red-custom  # Use the custom image
    container_name: NodeREDContainer
    restart: always
    network_mode: host
    devices:
      - /dev/ttyCOM1:/dev/ttyCOM1
      - /dev/ttyCOM2:/dev/ttyCOM2
    group_add:
      - keep-groups
    volumes:
      - /data/user/node-red-podman/data:/data  # Persistent volume for flows and configurations
    stdin_open: true
    tty: true
```

```bash
chmod 777 data
```

### 5. Start the Container with Podman Compose

To start the container:

```bash
podman-compose up -d
```

To stop the container:

```bash
podman-compose down
```

---

### 6. Access Node-RED

1. **Check that the container is active**:
   
   ```bash
   podman ps
   ```

2. **Access Node-RED from your browser**:
   
   Open a browser and navigate to:
   
   ```
   http://<DEVICE_IP>:1880
   ```

3. **Verify Installed Modules**:
   
   - Go to the **Manage palette** menu in Node-RED.
   - Check that the **node-red-dashboard** and **node-red-contrib-modbus** modules are installed.

---

### 7. Export and Import the Image

#### **Export the Image**

To save the image as a tar file:

```bash
podman save -o node-red-custom.tar node-red-custom
```

#### **Import the Image**

To import the image on another system:

```bash
podman load -i node-red-custom.tar
```

---

## **Summary of Main Commands**

1. **Build the image**:
   
   ```bash
   podman build -t node-red-custom -f node-red.Dockerfile
   ```

2. **Start the container**:
   
   ```bash
   podman-compose up -d
   ```

3. **Access Node-RED**:
   
   ```
   http://<DEVICE_IP>:1880
   ```

4. **Export the image**:
   
   ```bash
   podman save -o node-red-custom.tar node-red-custom
   ```

5. **Import the image**:
   
   ```bash
   podman load -i node-red-custom.tar
   ```

---

## **Conclusion**

This guide provides a complete configuration for a **Node-RED** container on Podman with pre-installed **Dashboard** and **Modbus** modules, serial device access, and persistent configurations.