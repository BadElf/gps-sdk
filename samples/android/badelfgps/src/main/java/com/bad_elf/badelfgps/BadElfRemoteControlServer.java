package com.bad_elf.badelfgps;

import android.util.Log;

import java.io.IOException;
        import java.io.OutputStream;
        import java.io.PrintStream;
        import java.net.InetAddress;
        import java.net.NetworkInterface;
        import java.net.ServerSocket;
        import java.net.Socket;
        import java.net.SocketException;
        import java.util.Enumeration;
import java.util.Locale;

public class BadElfRemoteControlServer {

    public static final String TAG = "BadElfRemoteControlServer";

    //MainActivity activity;
    ServerSocket serverSocket;
    String message = "";
    static final int socketServerPORT = 8080;

    public BadElfRemoteControlServer() {
        //this.activity = activity;
        Thread socketServerThread = new Thread(new SocketServerThread());
        socketServerThread.start();
    }

    public int getPort() {
        return socketServerPORT;
    }

    public void onDestroy() {
        if (serverSocket != null) {
            try {
                serverSocket.close();
            } catch (IOException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        }
    }

    private class SocketServerThread extends Thread {

        public static final String TAG = "BadElfRemoteControlServer.SocketServerThread";

        int count = 0;

        @Override
        public void run() {
            try {
                // create ServerSocket using specified port
                serverSocket = new ServerSocket(socketServerPORT);
                Log.d(TAG, String.format(Locale.US,"Starting ServerSocket on %s port %d...",getIpAddress(), socketServerPORT));

                while (true) {
                    // block the call until connection is created and return
                    // Socket object
                    Socket socket = serverSocket.accept();
                    count++;
                    Log.d(TAG, "Got connection from: " + socket.getInetAddress() + ":" + socket.getPort());

                    SocketServerReplyThread socketServerReplyThread =
                            new SocketServerReplyThread(socket, count);
                    socketServerReplyThread.run();

                }
            } catch (IOException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        }
    }

    private class SocketServerReplyThread extends Thread {

        private Socket hostThreadSocket;
        int cnt;

        SocketServerReplyThread(Socket socket, int c) {
            hostThreadSocket = socket;
            cnt = c;
        }

        @Override
        public void run() {
            OutputStream outputStream;
            String msgReply = "Hello from Server, you are #" + cnt;

            try {
                outputStream = hostThreadSocket.getOutputStream();
                PrintStream printStream = new PrintStream(outputStream);
                printStream.print(msgReply);
                printStream.close();





                message += "replayed: " + msgReply + "\n";

//                activity.runOnUiThread(new Runnable() {
//
//                    @Override
//                    public void run() {
//                        activity.msg.setText(message);
//                    }
//                });

            } catch (IOException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
                message += "Something wrong! " + e.toString() + "\n";
            }

//            activity.runOnUiThread(new Runnable() {
//
//                @Override
//                public void run() {
//                    activity.msg.setText(message);
//                }
//            });
        }

    }

    public String getIpAddress() {
        String ip = "";
        try {
            Enumeration<NetworkInterface> enumNetworkInterfaces = NetworkInterface
                    .getNetworkInterfaces();
            while (enumNetworkInterfaces.hasMoreElements()) {
                NetworkInterface networkInterface = enumNetworkInterfaces
                        .nextElement();
                Enumeration<InetAddress> enumInetAddress = networkInterface
                        .getInetAddresses();
                while (enumInetAddress.hasMoreElements()) {
                    InetAddress inetAddress = enumInetAddress
                            .nextElement();

                    if (inetAddress.isSiteLocalAddress()) {
                        ip += "Server running at : "
                                + inetAddress.getHostAddress();
                    }
                }
            }

        } catch (SocketException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            ip += "Something Wrong! " + e.toString() + "\n";
        }
        return ip;
    }
}