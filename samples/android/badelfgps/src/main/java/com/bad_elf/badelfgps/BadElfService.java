/**
 * Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 * See LICENSE.txt for this sample's licensing information
 *
 */

package com.bad_elf.badelfgps;

import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.os.PowerManager;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.ref.WeakReference;
import java.nio.channels.AlreadyConnectedException;
import java.nio.channels.NotYetConnectedException;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

/**
 * This class is an Android Local Service that connects to and disconnects from a Bad Elf Device.
 * Once a connection is established data can be sent to and received from the Bad Elf Device.
 *
 * The class BadElfGpsConnection is a helper class that should be used for all interactions with
 * this Service.
 *
 */
public class BadElfService extends Service {

    private static final String TAG = "BadElfService";

    /**
     * The State of the connection to the Bad Elf Device
     *
     */
    public enum State {
        IDLE         (R.string.badElfGpsServiceStateIdle          ) ,
        CONNECTING   (R.string.badElfGpsServiceStateConnecting    ),
        CONNECTED    (R.string.badElfGpsServiceStateConnected     ),
        DISCONNECTING(R.string.badElfGpsServiceStateDisconnecting );

        private final int resID;

        State(int resID){
            this.resID = resID;
        }

        public String toString(Context context){
            return context.getResources().getString(resID);
        }
    }

    private State state = State.IDLE;
    private BluetoothDevice device;
    private BluetoothSocket socket;
    private OutputStream outStream;
    private final Object stateSync = new Object();
    private Thread serviceThread;

    /**
     * Start the Service
     *
     * This is called after connect calls startService.
     *
     * It creates a thread that connects to the Bad Elf Device. The Service will continue to run
     * until the thread exits which happens after disconnect is called or if there is an error.
     *
     */
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "onStartCommand");
        serviceThread = new Thread(runnable, TAG);
        serviceThread.start();
        return START_NOT_STICKY;
    }

    /**
     * Called when the BadElfGpsConnection constructor calls bindService
     * @param intent unused
     * @return our binder
     */
    @Override
    public IBinder onBind(Intent intent) {
        Log.d(TAG, "onBind");
        return binder;
    }

    /**
     * Called by the system to notify us when the service is no longer needed.
     */
    @Override
    public void onDestroy(){
        Log.d(TAG,"onDestroy");
        try {
            // We should always already be disconnected when onDestroy is called, but we will
            // call disconnect just in case.
            disconnect();
        }catch (NotYetConnectedException ignore){
            // This exception can be safely ignored because we must have already been disconnected.
        }
        try {
            // Wait for Service Thread to exit before returning from onDestroy.
            serviceThread.join();
        }catch(NullPointerException ignore){
            // This exception can be safely ignored because it happens if there is no thread to wait for
        }catch(InterruptedException e){
            Thread.currentThread().interrupt(); // Restore the interrupted status
        }
        Log.d(TAG,"onDestroy exiting");

    }

    protected static class BadElfBinder extends Binder{

        private WeakReference<BadElfService> weakBadElfService;

        /**
         * Construct BadElfBinder
         *
         * @param badElfService the BadElfService instance
         */
        public BadElfBinder(BadElfService badElfService){
            weakBadElfService = new WeakReference<>(badElfService);
        }

        /**
         * Called by BadElfGpsConnection.onServiceConnected to get the BadElfService instance
         *
         * @return the BadElfService instance
         */
        public BadElfService getServiceInstance(){
            return weakBadElfService.get();
        }
    }
    private final IBinder binder = new BadElfBinder(this);

    private List<BadElfGpsConnectionObserver> observers = new CopyOnWriteArrayList<>();

    /**
     * Add an observer
     *
     * @param observer an instance that implements BadElfGpsConnectionObserver
     */
    protected void addObserver(BadElfGpsConnectionObserver observer){
        observers.add(observer);
    }

    /**
     * Remove and observer
     *
     * @param observer an instance that implements BadElfGpsConnectionObserver
     */
    protected void removeObserver(BadElfGpsConnectionObserver observer){
        observers.remove(observer);
    }


    /**
     * Set the connection state
     *
     * This must only be called from inside a synchronized (stateSync) block
     *
     * @param newState the state to change to
     */
    private void setState(State newState){
        state = newState;
        Log.d(TAG, "setState("+newState+")");
        for(BadElfGpsConnectionObserver observer:observers){
            try {
                observer.onStateChanged(state);
            }catch (RuntimeException e){
                // don't let observer errors stop us
                Log.d(TAG,"observer.onStateChange", e);
            }
        }
    }

    /**
     * Get the state of the connection.
     *
     * @return the state of the connection
     *
     */
    protected State getState() {
        synchronized (stateSync){
            return state;
        }
    }

    /**
     * Set the Bad Elf Device.
     *
     * The Bad Elf Device can only be changed when the service state is Idle
     *
     * @param badElfDevice the Bad Elf Device
     */
    protected void setBadElfDevice(BadElfDevice badElfDevice) {
        synchronized (stateSync) {
            if( ! badElfDevice.getDevice().equals(device)) {
                // setting a new device
                if (state != State.IDLE) throw new AlreadyConnectedException();
                device = badElfDevice.getDevice();
            }
        }
    }


    /**
     * Connect to the Bad Elf Device
     *
     * This will start the service which will continue to run until disconnect is called or until
     * there is an error.
     */
    protected void connect() {

        synchronized (stateSync) {
            if(device == null) throw new IllegalStateException("No Bad Elf Device has been Set");
            if (state != State.IDLE) throw new AlreadyConnectedException();
            setState(State.CONNECTING);
        }
        Context appContext = this.getApplicationContext();
        appContext.startService(new Intent(appContext, BadElfService.class)); // start service
    }

    /**
     * Disconnect from the Bad Elf Device
     *
     * This disconnects by closing the socket which will cause the service to stop
     *
     */
    protected void disconnect() {
        synchronized (stateSync) {
            if (state == State.IDLE) throw new NotYetConnectedException();
            if (state == State.DISCONNECTING) return;

            setState(State.DISCONNECTING);
            try {
                socket.close(); // This will cause the Service Thread to exit
            } catch (IOException | NullPointerException ignore){
                // these exception can be safely ignored because we are trying to disconnect
            }
            try {
                serviceThread.interrupt(); // This will also cause the service thread to exit
            }catch(NullPointerException ignore){
                // this exception can be safely ignored because we are trying to disconnect
            }
        }
    }



    /**
     * Send data to the Bad Elf Device
     *
     * @param data the data to send
     */
    protected void sendData(final byte[] data) {
        synchronized (stateSync) {
            if (state != State.CONNECTED) throw new NotYetConnectedException();
        }
        if(data == null || data.length == 0)
            return;
        try {
            outStream.write(data);   // send data to Bad Elf Device
        } catch (IOException | NullPointerException e) {
            // Errors will cause us to disconnect
            // We will not propagate the errors here. The calls to onStateChanged will be the
            // notification of the error.
            try {
                disconnect();
            } catch (NotYetConnectedException ignore) {
                // If the IOException or NullPointerException was caused because we are
                // disconnecting, then calling disconnect will throw NotYetConnectedException
                // that we don't want to propagate.
            }
        }
    }

    private static final UUID SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb");

    private final ScheduledExecutorService sch = Executors.newSingleThreadScheduledExecutor();

    /**
     * This is the runnable for the Service Thread.
     *
     * When a connection to the Bad Elf Device is requested the BadElfService is started which
     * starts this runnable. It attempts to connect to the device and then runs until
     * disconnect. It then cleans up and exits.
     *
     */
    private final Runnable runnable = new Runnable() {
        @Override
        public void run() {

            Log.d(TAG, "Service Thread Starting");
            ScheduledFuture<?> pingFuture = null;
            PowerManager.WakeLock wakeLock = null;

            try {
                // Keep the CPU on while we are connected to the Bad Elf Device
                PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
                wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, TAG);
                wakeLock.acquire();

                // Attempt connect to the Device
                BluetoothAdapter.getDefaultAdapter().cancelDiscovery();
                socket = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID);
                socket.connect();// This blocks until it succeeds or throws an exception
                InputStream inStream = socket.getInputStream();
                outStream = socket.getOutputStream();
                // Connection succeeded

                synchronized (stateSync) {
                    if (state != State.CONNECTING) { // this happens if disconnect is called while connecting
                        return;
                    }
                    setState(State.CONNECTED);
                }

                // Call pingTask every 500 milli seconds because of an Android bug
                pingFuture = sch.scheduleAtFixedRate(pingTask, 2000, 500, TimeUnit.MILLISECONDS);


                byte[] buffer = new byte[1024];
                int bytesRead;

                // read from the InputStream until an exception occurs or until read returns -1
                // or until the thread is interrupted.
                while (-1 != (bytesRead = inStream.read(buffer)) && ! Thread.interrupted()  ) {

                    byte[] data = new byte[bytesRead];
                    System.arraycopy(buffer, 0, data, 0, bytesRead);
                    // Send The received data to any observers
                    for (BadElfGpsConnectionObserver observer : observers) {
                        try {
                            observer.onDataReceived(data);
                        } catch (RuntimeException e) {
                            // don't let observer errors stop us
                            Log.d(TAG, "observer.onDataReceived", e);
                        }
                    }
                }

            } catch (IOException ignore) {
                // nothing to do here, the finally clauses will clean everything up

            } finally {
                Log.d(TAG, "Service Thread finally");
                // Disconnected (or failed to connect)- Shut Everything Down


                if(pingFuture != null){
                    pingFuture.cancel(false);
                }
                if(socket != null) {
                    try {
                        socket.close();
                    } catch (IOException ignore) {
                        // This exception can be safely ignored because we just we are done with the socket
                    }
                    socket = null;
                }
                outStream = null;

                stopSelf();  // stop service. It will be destroyed if no one is bound to it.

                synchronized (stateSync) {
                    if(state == State.CONNECTING){
                        Log.d(TAG, "Failed to connect.");
                    }
                    setState(State.IDLE);
                }

                if(wakeLock != null){
                    wakeLock.release(); // let the CPU sleep
                }
                Log.d(TAG,"Service Thread Exiting");

                serviceThread = null;
            }
        }
    };



    static final byte[] pingJunk = {0};

    /**
     *  Send junk data to the Bad Elf Device because of an Android bug
     *
     *  https://code.google.com/p/android/issues/detail?id=66177
     *
     *  Android sends sniff mode request on a busy rfcomm connection
     *
     *  Suspected cause:
     *     Android only monitors the tx channel to determine if a connection is busy. Since we
     *     mostly only receive data from the Bad Elf Device, but rarely send any data, Android
     *     makes the wrong conclusion.
     *
     *  Workaround:
     *     Send junk data every ~500ms to Bad Elf device to prevent Android Device from commanding
     *     sniff mode.
     */
    private final Runnable pingTask = new Runnable() {

        @Override
        public void run() {

            sendData(pingJunk);
        }
    };
}
