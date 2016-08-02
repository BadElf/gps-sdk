/**
 * Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 * See LICENSE.txt for this sample's licensing information
 *
 */

package com.bad_elf.badelfgps;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.util.Log;

import com.bad_elf.badelfgps.BadElfService.State;

/**
 * This class controls the connection to a Bad Elf Device.
 *
 * Most of the actual work is performed by the BadElfService class.
 *
 * When this class is instantiated it Binds to the BadElfService and it Unbinds when onDestroy is
 * called. After Binding to the BadElfService connect can be called and the Service will be started
 * and will continue to run until disconnect is called or until there is an error.
 *
 */
public class BadElfGpsConnection {

    private static String TAG = "BadElfGpsConnection";

    private final BadElfGpsConnectionObserver observer;
    private final Context appContext;
    private BadElfService badElfService;

    /**
     * Create a BadElfGpsConnection instance
     *
     * @param observer A class that implements BadElfGpsConnectionObserver
     * @param context used to grab the application context that will be used to bind and unbind the Service
     */
    public BadElfGpsConnection(final BadElfGpsConnectionObserver observer, final Context context){
        this.observer = observer;
        appContext = context.getApplicationContext(); // get an application context so we don't hold the Activity context

        // Bind To the Service.
        Intent intent = new Intent(appContext, BadElfService.class);
        boolean bound = appContext.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
        Log.d(TAG, "bound = "+bound);
    }

    private final ServiceConnection serviceConnection = new ServiceConnection() {
        /**
         * Called when the service is connected to us
         *
         * @param name Unused
         * @param binder The Binder from the Service
         */
        @Override
        public void onServiceConnected(ComponentName name, IBinder binder) {
            Log.d(TAG, "onServiceConnected");
            badElfService =  ((BadElfService.BadElfBinder)binder).getServiceInstance(); // get the service instance
            badElfService.addObserver(observer); // add the observer to the service
            observer.onReady(); // tell the observer that we are ready to go
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            // onServiceDisconnected is only called if the service is killed or crashes.
            // but a local service runs in the same process as the app so if the
            // service gets killed or crashes the app will also be killed.
            // Meaning this code should never get called.
            throw new AssertionError("Unexpected onServiceDisconnected");
        }
    };


    /**
     * Destroy the BadElfGpsConnection instance
     *
     * NOTE: If there is an active connection to the Bad Elf Device this does not cause that to
     * disconnect. To disconnect from the Bad Elf Device disconnect must be called. The connection
     * to the Bad Elf Device is not tied to an instance of BadElfGpsConnection
     *
     */
    public void onDestroy(){
        Log.d(TAG, "onDestroy");
        try {
            ifBadElfServiceIsBound().removeObserver(observer);  // Tell the service the observer is not interested in hearing from it anymore.
            badElfService = null;
            appContext.unbindService(serviceConnection); // We don't need to talk to the service anymore.
        }catch (NotBoundToServiceException | IllegalArgumentException e){
            // This could happen if we call onDestroy before onServiceConnected runs or if
            // onDestroy is called twice. Ignore because we are already destroyed
        }
    }

    // Exception thrown if the wrapper methods below are called before onServiceConnected runs or
    // after onDestroy is called.
    public static class NotBoundToServiceException extends IllegalStateException {
        public NotBoundToServiceException() {
            super("Not Bound To Service Exception");
        }
    }

    /**
     * If not bound to service Throw NotBoundToServiceException
     *
     * @return a copied reference to the badElfService
     *
     */
    private BadElfService ifBadElfServiceIsBound(){
        BadElfService temp = badElfService;
        if (temp == null)
            throw new NotBoundToServiceException();
        return temp;
    }

    /**
     * The following five methods are wrappers around the methods in BadElfService
     *
     * If called when not bound to the BadElfService, NotBoundToServiceException will be thrown.
     *
     */

    public void  setBadElfDevice(BadElfDevice badElfDevice) {        ifBadElfServiceIsBound().setBadElfDevice((badElfDevice)); }
    public void  connect()                                  {        ifBadElfServiceIsBound().connect();                       }
    public void  sendData(final byte[] data)                {        ifBadElfServiceIsBound().sendData(data);                  }
    public void  disconnect()                               {        ifBadElfServiceIsBound().disconnect();                    }
    public State getState()                                 { return ifBadElfServiceIsBound().getState();                      }


    /**
     * Request Enum
     *
     * This enum is used to send data to the device to request a change in data rate and whether to
     * include satellite data.
     */
    public enum Request {
        ONE_HZ_INCLUDE_SATELLITES ( 1, true, "24be001105010205310132043301640d0a"),
        TWO_HZ_INCLUDE_SATELLITES ( 2, true, "24be001104010206310232043301630d0a"),
        FOUR_HZ_INCLUDE_SATELLITES( 4, true, "24be001107010203310432113301540d0a"),
        FIVE_HZ_INCLUDE_SATELLITES( 5, true, "24be001106010204310532043301600d0a"),
        TEN_HZ_INCLUDE_SATELLITES (10, true, "24be001108010202310a320433015b0d0a"),

        ONE_HZ_NO_SATELLITES      ( 1, false, "24be00110b0102ff310132043302630d0a"),
        TWO_HZ_NO_SATELLITES      ( 2, false, "24be0011100102fa310232043302620d0a"),
        FOUR_HZ_NO_SATELLITES     ( 4, false, "24be0011120102f8310432043302600d0a"),
        FIVE_HZ_NO_SATELLITES     ( 5, false, "24be0011130102f73105320433025f0d0a"),
        TEN_HZ_NO_SATELLITES      (10, false, "24be0011160102f4310a320433025a0d0a");

        public final byte[] data;
        public final int rate;
        public final boolean includeSatellites;

        /**
         * Construct a Request enum
         *
         * @param rate requested data rate
         * @param includeSatellites if true request will include satellites
         * @param messageString The data to send to the device encoded as a hex string.
         */
        Request(int rate, boolean includeSatellites, String messageString) {
            this.rate = rate;
            this.includeSatellites = includeSatellites;
            // convert the hex string to an Array of Bytes
            int len = messageString.length();
            byte[] temp = new byte[len / 2];
            for (int i = 0; i < len; i += 2) {
                temp[i / 2] = (byte) ((Character.digit(messageString.charAt(i), 16) << 4)
                        + Character.digit(messageString.charAt(i + 1), 16));
            }
            this.data=temp;
        }
    }



}