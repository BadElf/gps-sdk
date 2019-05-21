/**
 * Copyright (C) 2016 Bad Elf, LLC. All Rights Reserved.
 * See LICENSE.txt for this sample's licensing information
 *
 */

package com.bad_elf.gpssample;

import android.graphics.LightingColorFilter;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.text.Editable;
import android.text.Layout;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;

import com.bad_elf.badelfgps.BadElfDevice;
import com.bad_elf.badelfgps.BadElfRemoteController;
import com.bad_elf.badelfgps.BadElfService.State;
import com.bad_elf.badelfgps.BadElfGpsConnection;
import com.bad_elf.badelfgps.BadElfGpsConnectionObserver;

/**
 * This Activity lets the user connect to and disconnect from a Bad Elf Device. The data received
 * from the device is displayed and the user can send requests to change the data rate and
 * data format.
 *
 * This activity communicates with the Device using the BadElfGpsConnection class and through
 * callbacks by implementing the BadElfGpsConnectionObserver interface.
 *
 */
public class BadElfDeviceDataActivity extends AppCompatActivity implements BadElfGpsConnectionObserver {

    private static final String TAG = "BadElfDeviceDataActvty";

    private Button connectDisconnectButton;
    private TextView stateView;
    private List<Button> requestButtons; // The 10 request buttons
    private TextView receivedDataView;

    private BadElfDevice badElfDevice;  // The Bad Elf device we will communicate with
    private BadElfGpsConnection badElfConnection;
    private BadElfRemoteController remoteControl;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        badElfDevice = getIntent().getParcelableExtra(BadElfDevice.TAG);

        remoteControl = getIntent().getParcelableExtra(BadElfRemoteController.TAG);
        remoteControl.setSelectedDevice(badElfDevice);

        assert getSupportActionBar() != null;
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        setTitle(badElfDevice.toString());

        setContentView(R.layout.activity_bad_elf_device_data);

        connectDisconnectButton = (Button)findViewById(R.id.ConnectDisconnectButton);
        connectDisconnectButton.setOnClickListener(onConnectDisconnectButtonClicked);

        stateView = (TextView)findViewById(R.id.State);

        requestButtons = new ArrayList<>();

        // Find the Request buttons and link them to the Request Enum
        initializeRequestButtons(R.id.SatelliteButtons   , true);
        initializeRequestButtons(R.id.NoSatelliteButtons , false);

        // make sure the number of buttons found in the layout file matches the Request Enum
        if (requestButtons.size() != BadElfGpsConnection.Request.values().length) throw new AssertionError();

        receivedDataView = (TextView)findViewById(R.id.receivedData);
        receivedDataView.setMovementMethod(new ScrollingMovementMethod());

        // Create a BadElfGpsConnection instance. This will cause our implementation of
        // BadElfGpsConnectionObserver.onReady to be called.
        // Note: this does not actually connect to the Bad Elf Device. To connect to the Bad Elf
        // Device after onReady is called, call badElfConnection.setBadElfDevice() and
        // badElfConnection.connect().
        badElfConnection = new BadElfGpsConnection(this, this);
    }

    @Override
    protected void onDestroy() {
        Log.d(TAG, "onDestroy");
        super.onDestroy();
        badElfConnection.onDestroy();  // Destroy our link to the connection service.
                                       // NOTE: If there is an active connection to the Bad Elf
                                       // Device this does not cause that to disconnect. To
                                       // disconnect from the Bad Elf Device call
                                       // badElfConnection.disconnect(). This way the connection
                                       // to the Bad Elf Device is not tied to the Activity Life
                                       // Cycle and will not be dropped when the android device
                                       // orientation changes.
    }

    // This is the index in requestButtons of the last request button pressed
    private int lastRequestIndex = -1;
    private static final String LAST_REQUEST_INDEX="LAST_REQUEST_INDEX";

    @Override
    protected void onSaveInstanceState(Bundle savedInstanceState) {
        Log.d(TAG, "onSaveInstanceState");
        savedInstanceState.putInt(LAST_REQUEST_INDEX, lastRequestIndex);
        super.onSaveInstanceState(savedInstanceState);
    }

    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        Log.d(TAG, "onRestoreInstanceState");
        super.onRestoreInstanceState(savedInstanceState);
        lastRequestIndex = savedInstanceState.getInt(LAST_REQUEST_INDEX);
        if(lastRequestIndex != -1){
            highlightButton(requestButtons.get(lastRequestIndex));
        }
    }

    /**
     * Initialize request buttons and add them to the requestButtons array
     *
     * Find the buttons that are children of the given view id. For each button found add it to the
     * array, link the corresponding Request Enum, set the text, and set the listener.
     *
     * @param id The view id of the parent view of some request buttons
     * @param includeSatellites the request type matching the buttons in the parent view
     */
    private void initializeRequestButtons(int id, boolean includeSatellites){
        final ViewGroup buttonGroup = (ViewGroup)findViewById(id);
        for (int i = 0; i < buttonGroup.getChildCount(); i++){
            Button b = (Button)buttonGroup.getChildAt(i);

            // Get the next request
            BadElfGpsConnection.Request request = BadElfGpsConnection.Request.values()[requestButtons.size()];

            // make sure it is the correct type
            if (request.includeSatellites != includeSatellites) throw new AssertionError();

            requestButtons.add(b);

            b.setTag(request);  // Add the Request item to the button
            b.setText(getString(R.string.badElfGpsRequestRate, request.rate)); // set the text of the button to the request rate
            b.setOnClickListener(onRequestButtonClicked);
        }

    }

    /**
     * Called when the Connect/Disconnect button is pressed
     */
    private View.OnClickListener onConnectDisconnectButtonClicked = new View.OnClickListener() {
        public void onClick(View button) {
            if(badElfConnection.getState() == State.IDLE) {
                // if not connected, Connect to the Bad Elf Device
                receivedDataView.setText(""); // clear old received data
                badElfConnection.connect();
            }else{
                // if connected, disconnect
                badElfConnection.disconnect();
            }
        }
    };

    /**
     * Clear the highlighting on all the request buttons
     */
    private void resetRequestButtonColor() {
        for (Button b : requestButtons) {
            b.getBackground().setColorFilter(null);
        }
    }

    /**
     * Highlight request button when pressed
     *
     * @param button The button to highlight
     */
    private void highlightButton(Button button){
        button.getBackground().setColorFilter(new LightingColorFilter(0xFFC0ffC0, 0xFF002000));
    }

    /**
     * Called when a Request button is pressed.
     */
    private View.OnClickListener onRequestButtonClicked = new View.OnClickListener() {
        public void onClick(View view) {
            Button button = (Button)view;
            resetRequestButtonColor();
            highlightButton(button);
            lastRequestIndex = requestButtons.indexOf(button); // save the index so we can restore highlight after screen rotation

            BadElfGpsConnection.Request request = (BadElfGpsConnection.Request)button.getTag(); // get the request

            badElfConnection.sendData(request.data); // send the request data to the connection
        }
    };

    /**
     * This makes the activity exit when back is pressed
     */
    @Override
    public boolean onOptionsItemSelected(MenuItem item){
        int id = item.getItemId();

        if (id==android.R.id.home) {
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    /**
     * Update the State field, request buttons and connect/disconnect button when the connection
     * state changes.
     *
     * @param newState the new state
     */
    private void updateGui(final State newState){
        final boolean isConnected = (newState == State.CONNECTED);
        final boolean isIdle = (newState == State.IDLE);
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                stateView.setText(newState.toString(BadElfDeviceDataActivity.this));
                if (requestButtons.get(0).isEnabled() != isConnected) {
                    // if the request buttons are not in the correct state, change them.
                    for (Button b : requestButtons) {
                        b.setEnabled(isConnected);
                    }
                }
                connectDisconnectButton.setText(BadElfDeviceDataActivity.this.getResources().getString(
                        isIdle ? R.string.badElfGpsConnect : R.string.badElfGpsDisconnect
                ));
            }
        });

    }

    /**
     * Called when we are connected to the Service.
     *
     * This does not mean we are connected to the Bad Elf Device. The call to
     * badElfConnection.getState() will tell us if we are connected to a Bad Elf Device
     */
    @Override // this is a method of the BadElfGpsConnectionObserver
    public void onReady(){
        Log.d(TAG, "onReady");
        updateGui(badElfConnection.getState());
        connectDisconnectButton.setEnabled(true);
        badElfConnection.setBadElfDevice(badElfDevice);
    }


    /**
     * Called when the state of the Connection to the Bad Elf Device changes
     *
     * @param newState the state we just changed to.
     */
    @Override // this is a method of the BadElfGpsConnectionObserver
    public void onStateChanged(final State newState) {
        Log.d(TAG, String.format("OnStateChanged %s", newState));
        updateGui(newState);
    }

    /**
     * Called when ever we receive data from the Bad Elf Device
     *
     * @param data the received data
     */
    @Override // this is a method of the BadElfGpsConnectionObserver
    public void onDataReceived(final byte[] data){

        Log.d(TAG, String.format("RX bytes: %d", data.length));

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                receivedDataView.append(new String(data, Charset.forName("ISO-8859-1")));
                // Just keep the last 100 lines
                int linesToRemove = receivedDataView.getLineCount() - 100;
                if (linesToRemove > 0) {
                    for (int i = 0; i < linesToRemove; i++) {
                        Editable text = receivedDataView.getEditableText();
                        int lineStart = receivedDataView.getLayout().getLineStart(0);
                        int lineEnd = receivedDataView.getLayout().getLineEnd(0);
                        text.delete(lineStart, lineEnd);
                    }
                }
                final Layout layout = receivedDataView.getLayout();
                if(layout != null){
                    int scrollDelta = layout.getLineBottom(receivedDataView.getLineCount() - 1)
                            - receivedDataView.getScrollY() - receivedDataView.getHeight();
                    if(scrollDelta > 0)
                        receivedDataView.scrollBy(0, scrollDelta);
                }


            }
        });
    }

}
