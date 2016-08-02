/**
 * Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 * See LICENSE.txt for this sample's licensing information
 *
 */

package com.bad_elf.gpssample;

import android.support.v7.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ListView;
import android.widget.TextView;

import com.bad_elf.badelfgps.BadElfDevice;

import java.util.List;

/**
 * This Activity displays any paired Bad Elf Devices and lets the user select one to connect with.
 */
public class BadElfDeviceListActivity extends AppCompatActivity {
    private static final String TAG = "BadElfDeviceListActvty";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_bad_elf_device_list);

        final ListView listView = (ListView) findViewById(R.id.listView);


        try {
            List<BadElfDevice> badElfDevices = BadElfDevice.getPairedBadElfDevices(this);
            final ArrayAdapter<BadElfDevice> adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, badElfDevices);

            listView.setAdapter(adapter);
            listView.setOnItemClickListener(listener);

        } catch (RuntimeException e) {
            // Errors: Bluetooth not enabled or no paired Bad Elf Devices
            final TextView errorMessage = (TextView) findViewById(R.id.ErrorMessage);
            listView.setVisibility(View.GONE);
            errorMessage.setText(e.getMessage());
            errorMessage.setVisibility(View.VISIBLE);

        }


    }


    /**
     * Called when the user clicks on a Bad Elf Device
     *
     * Starts the BadElfDeviceDataActivity
     *
     */
    private AdapterView.OnItemClickListener listener = new AdapterView.OnItemClickListener() {
        @Override
        public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
            BadElfDevice badElfDevice = (BadElfDevice) parent.getItemAtPosition(position);
            Log.d(TAG, "Clicked " + badElfDevice.toString());
            Intent deviceDataIntent = new Intent(BadElfDeviceListActivity.this, BadElfDeviceDataActivity.class);
            deviceDataIntent.putExtra(BadElfDevice.TAG, badElfDevice);
            startActivity(deviceDataIntent);
        }
    };

}



