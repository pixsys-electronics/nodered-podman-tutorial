# **Create your own Node-RED Image with Podman**
<p align="left">
   <img src="assets/node-red-icon.png" alt="NodeRedIcon" width="10%">
   <img src="assets/podman-icon.png" alt="PodmanIcon" width="10%">
</p>

## **Objective** 🔍

Run a Podman container with:

- Pre-installed Node-RED
- Configured **dashboard**, **serial-port**, and **modbus** modules
- Access to `/dev/ttyCOM1` and `/dev/ttyCOM2` devices (for Modbus)
- Persistent volume to save Node-RED flows and configurations

## Prerequisites
- A [WebPanel (WP)](https://www.pixsys.net/en/hmi-panel-pc/web-panel) or [TouchController (TC)](https://www.pixsys.net/en/programmable-devices/hmi-codesys) device with a [WebVisu](https://github.com/tnentwig/WebVisu) license.
- Basic knowledge of Linux commands (optional if you use GUIs)
- Basic knowledge of [podman](https://podman.io/) and containers
- Basic knowledge of [Node-RED](https://nodered.org/) framework
- Basic knowledge of the [SSH](https://en.wikipedia.org/wiki/Secure_Shell) protocol

## **Steps** 👣

### 1. Connect to the Device and Prepare the Working Directory

#### Linux command-line

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

#### WinSCP
1. **Connect to the device via SSH** using the **`user`** account and navigate to `/data/user`:

   <img src="assets/winscp0.png" alt="WinScp0" width="80%">

2. Navigate to the `New` menu and choose the `Directory` option

   <img src="assets/winscp1.png" alt="WinScp0" width="80%">

3. Create the `node-red-podman` directory and give it RWX permission for ownwer, group, and other users

   <img src="assets/winscp2.png" alt="WinScp0" width="80%">

   **Note: you need to use these set of permissions only if you are going to run the container using Cockpit: this is due to the lack of options for the *podman run* command. If you are going to run the container via Linux command-line, you can give the created folder ONLY RWX permissions for the owner (first row of the permissions table), and leave the other rows empty, to enhance the security. This last is also the suggested way to run the container**
---

### 2. Setup the image

#### Manual creation
Going for a manual image creation allows you to have a custom image with every module you need, without manually install it later on the Node-RED GUI. This is the most portable and recommended way.

**Note: follow the steps below only if you are going to run your container using command-line**

Create a file named **`node-red.Dockerfile`** with the following content:

```dockerfile
# Use Node-RED as base
FROM docker.io/nodered/node-red:3.1.15

# Maintainer information
LABEL maintainer="YourName <youremail@example.com>"

# Install additional modules: Dashboard, OPC-UA, InfluxDB
RUN npm install node-red-node-serialport node-red-dashboard node-red-contrib-modbus node-red-contrib-modbus-flex-server && \
    npm cache clean --force

# Expose port 1880 for Node-RED access
EXPOSE 1880
```

Optionally (but recommended) you can create a podman-compose file that allows you to have a more flexible way to manage you container.
To do so, create a file named **`node-red-compose.yml`** with the following content:

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
    group_add:
      - keep-groups
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

#### Cockpit
If you are not familiar with command-lines, you can do everything from the Cockpit GUI.

0. Log-in into Cockpit from you WP, TC or directly from a PC through a browser at `http://<DEVICE_IP>:9443`
1. Navigate to the `Podman containers` tab in the side-menu.

   <img src="assets/dockergui0.png" alt="Cockpit0" width="80%">

2. Choose "Download new image" on the kebab menu (3 vertical points) in the `Images` section

   <img src="assets/dockergui1.png" alt="Cockpit1" width="80%">

3. Select the `docker.io` registry and type `node-red` inside the search input text

   <img src="assets/dockergui2.png" alt="Cockpit2" width="80%">

4. Select the `docker.io/nodered/node-red` image and press the "Download" button

   <img src="assets/dockergui4.png" alt="Cockpit3" width="80%">

5. At the end of the download, you will be able to see the downloaded image inside the `Images` section

   <img src="assets/dockergui6.png" alt="Cockpit3" width="80%">


### 3. Create and start the Container

#### Linux command-line
If you didn't create a `node-red-compose.yml` and you just want to use podman, you need to:

1. Build the image

   ```bash
   podman build -t node-red-custom -f node-red.Dockerfile .
   ```

2. Run the container

   ```bash
   podman run --group-add=keep-groups --userns=keep-id -u $(id -u):$(id -g) -v /data/user/node-red-podman/data:/data -p 1880:1880 --device=/dev/ttyCOM1 --device=/dev/ttyCOM2 node-red-custom   
   ```

Otherwise, if you want to go for podman-compose, you only need to run:

```bash
MY_UID=$(id -u) MY_GID=$(id -g) podman-compose -f node-red-compose.yml up --build
```
**Note: *MY_UID* and *MY_GID* are set to user ID and group ID of your current user, which should be *user*. This way, everything written by the container user will have the same ownership of your host user.**

To make sure the container is running, run:

```bash
podman ps
```

The output should be something like this:

```bash
CONTAINER ID	IMAGE	COMMAND	CREATED	STATUS	PORTS	NAMES
004d1d95bbd0	localhost/node-red-custom:latest	2 minutes ago	Up 2 minutes	0.0.0.0:1880->1880/tcp	NodeREDContainer
```

#### Cockpit
1. On the `Containers` section, press the "Create container" button. A menu will appear.

   <img src="assets/dockergui7.png" alt="Cockpit3" width="80%">

2. Fill the `Details` section as shown below:

   <img src="assets/dockergui8.png" alt="Cockpit3" width="80%">

3. Navigate to the `Integration` tab and fill it as shown below:

   <img src="assets/dockergui9.png" alt="Cockpit3" width="80%">

4. Navigate to the `Health check` tab and fill it as shown below:

   <img src="assets/dockergui10.png" alt="Cockpit3" width="80%">

5. Press the "Create and run" button. After the creation, you will be able to see the created container inside the `Container` section, with a "Running" value on the `State` column.

   <img src="assets/dockergui11.png" alt="Cockpit3" width="80%">


### 4. Configure Node-RED

1. **Access Node-RED from your browser**:
   
   Open a browser and navigate to:
   
   ```
   http://<DEVICE_IP>:1880
   ```

   <img src="assets/node-red-welcome.png" alt="NodeRedWelcome" width="60%">

2. **Install and verify the modules**:
   
   1. Go to the **Manage palette** menu in Node-RED by pressing the hamburger menu icon on the top right

   <img src="assets/node-red-hamburger.png" alt="NodeRedWelcome" width="60%">

   2. If you have followed the `Cockpit` guide, you will need to manually install the *dashboard* and the *modbus* modulesm otherwise go directly to section 4.3. Type `node-red-dashboard` and press the "Install" button to install the module. Do the same thing with `node-red-contrib-modbus` and `node-red-contrib-serial-port`

   <img src="assets/node-red-install-module.png" alt="NodeRedWelcome" width="60%">

   3. Check that the modules are installed.

   <img src="assets/node-red-nodes.png" alt="NodeRedWelcome" width="60%">

3. **Import a flow**

   If you want to make sure everything works correctly, use this [flow](https://nodered.org/docs/user-guide/editor/workspace/flows) file as a test:

   ```json
      [
    {
        "id": "1e6b97b5.687fd8",
        "type": "tab",
        "label": "Dashboard",
        "disabled": false,
        "info": ""
    },
    {
        "id": "7c8f99d9.196b98",
        "type": "ui_text",
        "z": "1e6b97b5.687fd8",
        "group": "dd4567b9.6a4c18",
        "order": 1,
        "width": "12",
        "height": "1",
        "name": "Title",
        "label": "Dashboard - Random Data Display",
        "format": "{{msg.payload}}",
        "layout": "col-center",
        "x": 330,
        "y": 120,
        "wires": []
    },
    {
        "id": "2e4a56f8.cfa23a",
        "type": "ui_gauge",
        "z": "1e6b97b5.687fd8",
        "name": "Random Gauge",
        "group": "dd4567b9.6a4c18",
        "order": 2,
        "width": "6",
        "height": "6",
        "gtype": "gage",
        "title": "Random Value",
        "label": "%",
        "format": "{{value}}",
        "min": "0",
        "max": "100",
        "colors": ["#00b500","#e6e600","#ca3838"],
        "seg1": "30",
        "seg2": "70",
        "x": 320,
        "y": 240,
        "wires": []
    },
    {
        "id": "3b9ddefd.32b9d",
        "type": "ui_chart",
        "z": "1e6b97b5.687fd8",
        "name": "Time-based Chart",
        "group": "dd4567b9.6a4c18",
        "order": 3,
        "width": "6",
        "height": "6",
        "label": "Random Time Chart",
        "chartType": "line",
        "legend": "false",
        "xformat": "HH:mm:ss",
        "interpolate": "linear",
        "nodata": "",
        "ymin": "0",
        "ymax": "100",
        "removeOlder": 1,
        "removeOlderPoints": "",
        "removeOlderUnit": "3600",
        "cutout": 0,
        "useOneColor": false,
        "colors": ["#00b500","#e6e600","#ca3838"],
        "outputs": 1,
        "useDifferentColor": false,
        "x": 600,
        "y": 240,
        "wires": []
    },
    {
        "id": "74b1aef8.e7e0d8",
        "type": "function",
        "z": "1e6b97b5.687fd8",
        "name": "Generate Random Data",
        "func": "msg.payload = Math.floor(Math.random() * 100);\nreturn msg;",
        "outputs": 1,
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 130,
        "y": 240,
        "wires": [
            [
                "2e4a56f8.cfa23a",
                "3b9ddefd.32b9d"
            ]
        ]
    },
    {
        "id": "e0e9bd3c.a8ae2",
        "type": "inject",
        "z": "1e6b97b5.687fd8",
        "name": "",
        "props": [
            {
                "p": "payload"
            }
        ],
        "repeat": "1",
        "crontab": "",
        "once": true,
        "onceDelay": 0.1,
        "topic": "",
        "payloadType": "date",
        "x": 130,
        "y": 160,
        "wires": [
            [
                "74b1aef8.e7e0d8"
            ]
        ]
    },
    {
        "id": "dd4567b9.6a4c18",
        "type": "ui_group",
        "z": "",
        "name": "Random Data",
        "tab": "fe9b4293.8df8e",
        "order": 1,
        "disp": true,
        "width": "12",
        "collapse": false
    },
    {
        "id": "fe9b4293.8df8e",
        "type": "ui_tab",
        "z": "",
        "name": "Main Dashboard",
        "icon": "dashboard",
        "order": 1,
        "disabled": false,
        "hidden": false
    }
   ]
   ```

   1. Go to the **Import** menu by pressing the hamburger menu icon on the top right, and paste the file above, then press the "Import" button.

      <img src="assets/node-red-import.png" alt="NodeRedWelcome" width="80%">
      <img src="assets/node-red-import-node.png" alt="NodeRedWelcome" width="80%">
      <img src="assets/node-red-diagram.png" alt="NodeRedWelcome" width="80%">
   
   2. Press the red "Deploy" button on the top-right of the page
   3. Navigate to `<DEVICE_ADDRESS>:1880/ui`. The output should be something like this:

      <img src="assets/node-red-dashboard.png" alt="NodeRedWelcome" width="80%">

### 5. Set the dashboard as main page
If you want the dashboard to be the main application of your WP/TC, access Cockpit and navigate to `WP Settings` and look for "Main application settings". Here, set the URL to `http://127.0.0.1:1880/ui` or `http://localhost:1880/ui`, and press the "Save" button. After then next reboot, the dashboard will appear in fullscreen-mode.

   <img src="assets/cockpit-set-url.png" alt="NodeRedWelcome" width="80%">

### 6. (Optional) Export and Import the Image
If you have manually created and built the node-red-custom image, and you want to use it in other WP/TC, you can export it from your current device and then load it in another, using podman.

To save the image as a tar archive:

```bash
podman save -o node-red-custom.tar node-red-custom
```

To import the image on another system:

```bash
podman load -i node-red-custom.tar
```

## **Conclusion** 🏁

This guide provides a complete configuration for a **Node-RED** container on Podman with pre-installed **Dashboard** and **Modbus** modules, serial device access, and persistent configurations.

<img src="assets/pixsys-icon.png" alt="PixsysIcon" width="50%">
