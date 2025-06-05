# **Building your own Node-RED Image with Podman**
<p align="left">
   <img src="assets/node-red-icon.png" alt="NodeRedIcon" width="10%">
   <img src="assets/podman-icon.png" alt="PodmanIcon" width="10%">
</p>

## **Objective**

Run a Podman container with:

- Pre-installed Node-RED
- Configured **dashboard**, **serial-port**, and **modbus** modules
- Access to `/dev/ttyUSB0` devices (for Modbus)
- Persistent volume to save Node-RED flows and configurations

## Prerequisites
- A [WebPanel (WP)](https://www.pixsys.net/en/hmi-panel-pc/web-panel) or [TouchController (TC)](https://www.pixsys.net/en/programmable-devices/hmi-codesys) device with a [WebVisu](https://github.com/tnentwig/WebVisu) license.
- Basic knowledge of Linux commands
- Basic knowledge of [podman](https://podman.io/) and containers
- Basic knowledge of [Node-RED](https://nodered.org/) framework

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

### 3. Create the Podman Compose File

Create a file named **`node-red-compose.yml`** with the following content:

```yaml
services:
  nodered:
    # tell podman-compose to build the previous custom node-red image
    build:
      context: .
      dockerfile: node-red.Dockerfile
    image: node-red-custom
    container_name: NodeREDContainer
    restart: always
    group_add: keep-groups
    userns_mode: keep-id # map my host user to the user namespace of the container 
    user: ${MY_UID}:${MY_GID}
    ports:
        - 1880:1880 # map container port 1880 to host port 1880
    devices:
      - /dev/ttyCOM1:/dev/ttyCOM1 # map devices
      - /dev/ttyCOM2:/dev/ttyCOM2
    volumes:
      - /data/user/node-red-podman/data:/data  # Persistent volume for flows and configurations
```

### 5. Start the Container with Podman Compose

To start the container:

```bash
MY_UID=$(id -u) MY_GID=$(id -g) podman-compose -f node-red-compose.yml -d up --build
```
**Note: *MY_UID* and *MY_GID* are set to user ID and group ID of your current user, which should be *user*. This way, everything written by the container user will have the same ownership of your host user.**

To check logs:

```bash
podman logs -f NodeREDContainer
```

To stop the container:

```bash
podman-compose -f node-red-compose.yml down
```

---

### 6. Access Node-RED

1. **Check that the container is running**:
   
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

1. **Start the container**:
   
   ```bash
   MY_UID=$(id -u) MY_GID=$(id -g) podman-compose -f node-red-compose.yml -d up --build
   ```

2. **Export the image**:
   
   ```bash
   podman save -o node-red-custom.tar node-red-custom
   ```

3. **Import the image**:
   
   ```bash
   podman load -i node-red-custom.tar
   ```

---

## **Conclusion**

This guide provides a complete configuration for a **Node-RED** container on Podman with pre-installed **Dashboard** and **Modbus** modules, serial device access, and persistent configurations.

<img src="assets/pixsys-icon.png" alt="PixsysIcon" width="50%">
