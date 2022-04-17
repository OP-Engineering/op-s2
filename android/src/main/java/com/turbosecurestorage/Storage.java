package com.turbosecurestorage;

import android.content.Context;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

public final class Storage {

    public static void writeValues(Context context, String filename, byte[] bytes) throws IOException {
        FileOutputStream fos = context.openFileOutput(filename, Context.MODE_PRIVATE);
        fos.write(bytes);
        fos.close();
    }

    public static byte[] readValues(Context context, String filename) throws IOException {
        FileInputStream fis = context.openFileInput(filename);
        ByteArrayOutputStream baos = new ByteArrayOutputStream(1024);
        byte[] buffer = new byte[1024];
        int bytesRead = fis.read(buffer);
        while(bytesRead != -1) {
            baos.write(buffer, 0, bytesRead);
            bytesRead = fis.read(buffer);
        }
        return baos.toByteArray();
    }

    public static boolean exists(Context context, String filename) throws IOException {
        File file = context.getFileStreamPath(filename);
        return file != null && file.exists();
    }

    public static void resetValues(Context context, String[] filenames) {
        for(String filename : filenames) {
            context.deleteFile(filename);
        }
    }
}