package com.scanlibrary;

import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.app.Dialog;
import android.app.DialogFragment;
import android.content.DialogInterface;
import android.os.Bundle;

@SuppressLint("ValidFragment")
public class SingleButtonDialogFragment extends DialogFragment {

    protected int positiveButtonTitle;
    protected String message;
    protected String title;
    protected boolean isCancelable;

    public SingleButtonDialogFragment(int positiveButtonTitle,
                                      String message, String title, boolean isCancelable) {
        this.positiveButtonTitle = positiveButtonTitle;
        this.message = message;
        this.title = title;
        this.isCancelable = isCancelable;
    }


    @Override
    public Dialog onCreateDialog(Bundle savedInstanceState) {
        AlertDialog.Builder builder = new AlertDialog.Builder(getActivity())
                .setTitle(title)
                .setCancelable(isCancelable)
                .setMessage(message)
                .setPositiveButton(positiveButtonTitle,
                        new DialogInterface.OnClickListener() {

                            @Override
                            public void onClick(DialogInterface dialog,
                                                int which) {

                            }
                        });

        return builder.create();
    }
}