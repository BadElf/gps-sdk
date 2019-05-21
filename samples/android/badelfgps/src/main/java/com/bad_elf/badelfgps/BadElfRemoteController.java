package com.bad_elf.badelfgps;

import java.util.List;
import com.bad_elf.badelfgps.BadElfRemoteControlServer;

public class BadElfRemoteController {

    public static final String TAG = "BadElfRemoteController";

    private List<BadElfDevice> badElfDevices;
    private BadElfRemoteControlServer server;
    private BadElfDevice selectedDevice;


    public void start() {
        server = new BadElfRemoteControlServer();
    }

    public void stop() {

    }

    public void setDeviceList(List<BadElfDevice> badElfDevices) {
        this.badElfDevices = badElfDevices;
    }

    public void setSelectedDevice(BadElfDevice device) {
        this.selectedDevice = device;
    }

}
