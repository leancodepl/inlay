package com.idlefish.flutterboost.example;

public class Ball implements Cloneable {
    public float aX;// Acceleration
    public float aY;// Acceleration Y
    public float vX;// Velocity X
    public float vY;// Velocity Y
    public float x;// Position X
    public float y;// Position Y
    public int color;// Color
    public float r;// Radius


    public Ball clone() {
        Ball clone = null;
        try {
            clone = (Ball) super.clone();
        } catch (CloneNotSupportedException e) {
            e.printStackTrace();
        }
        return clone;
    }
}