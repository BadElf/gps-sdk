/**
 * Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 * See LICENSE.txt for this sample's licensing information
 *
 */

package com.bad_elf.badelfgps;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.os.Parcel;
import android.os.Parcelable;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * This class represents a Bad Elf GPS device.
 *
 * It is a wrapper around an android BluetoothDevice.
 *
 */
public class BadElfDevice implements Parcelable {

    public static final String TAG = "BadElfDevice";

    /**
     * Gets paired Bad Elf Devices
     *
     * @param context Context just needed to get error messages
     *
     * @return A List of paired BadElfDevices
     *
     * @throws UnsupportedOperationException if this android device does not support bluetooth
     * @throws IllegalStateException if Bluetooth is not enabled or if there are no paired Bad Elf
     *          Devices
     */
    public static List<BadElfDevice> getPairedBadElfDevices(Context context){

        BluetoothAdapter bluetoothAdapter;

        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (bluetoothAdapter == null) {
           throw new UnsupportedOperationException(context.getString(R.string.badElfGpsErrorNoBluetooth));
        }
        if (!bluetoothAdapter.isEnabled()) {
            throw new IllegalStateException(context.getString(R.string.badElfGpsErrorBluetoothDisabled));
        }

        List<BadElfDevice> result = new ArrayList<>();

        Set<BluetoothDevice> pairedDevices = bluetoothAdapter.getBondedDevices();
        Log.d(TAG,String.format(Locale.US,"Found %d pairedDevices",pairedDevices.size()));

        for (BluetoothDevice device : pairedDevices) {
            if( device.getName().startsWith("Bad Elf") ) {
                result.add(new BadElfDevice(device));
            }
        }

        if( result.isEmpty()){
            throw new IllegalStateException(context.getString(R.string.badElfGpsErrorNoPairedDevices));
        }

        return result;

    }


    private BluetoothDevice device;

    /**
     * Get the wrapped Bluetooth device
     *
     * @return The BluetoothDevice
     */
    protected BluetoothDevice getDevice(){
        return device;
    }

    /**
     * Construct a BadElfDevice
     *
     * The constructor is private so only the static method getPairedDevices can call it.
     *
     * @param device A paired Bad Elf BluetoothDevice
     */
    private BadElfDevice(BluetoothDevice device){
        this.device = device;
    }

    /**
     * This is used by BadElfDeviceList to display the device name
     *
     * @return device name
     */
    @Override
    public String toString(){
        return device.getName();
    }

    /**
     * The following four methods implement the Parcelable interface so that BadElfDevice instances
     * can be passed through an Intent.
     */

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeParcelable(this.device, flags);
    }

    protected BadElfDevice(Parcel in) {
        this.device = in.readParcelable(BluetoothDevice.class.getClassLoader());
    }

    public static final Parcelable.Creator<BadElfDevice> CREATOR = new Parcelable.Creator<BadElfDevice>() {
        @Override
        public BadElfDevice createFromParcel(Parcel source) {
            return new BadElfDevice(source);
        }

        @Override
        public BadElfDevice[] newArray(int size) {
            return new BadElfDevice[size];
        }
    };
}
