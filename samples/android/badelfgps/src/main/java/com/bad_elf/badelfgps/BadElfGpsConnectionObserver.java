/**
 * Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 * See LICENSE.txt for this sample's licensing information
 *
 */

package com.bad_elf.badelfgps;

/**
 * Implement this interface to receive callbacks from BadElfGpsConnection and BadElfGpsService
 */
public interface BadElfGpsConnectionObserver {

    /**
     * This is called by BadElfGpsConnection when it has bound to the BadElfService.
     *
     * After this method is called the other methods of BadElfGpsConnection can be called.
     */
    void onReady();

    /**
     * This is called by BadElfService when the connection state changes.
     *
     * @param newState the new connection state
     */
    void onStateChanged(final BadElfService.State newState);

    /**
     * This is called by BadElfService when data is received from the Bad Elf Device
     *
     * @param data the received data
     */
    void onDataReceived(final byte[] data);
}
