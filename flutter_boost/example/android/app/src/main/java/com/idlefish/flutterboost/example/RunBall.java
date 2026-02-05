package com.idlefish.flutterboost.example;

import android.animation.ValueAnimator;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Point;
import androidx.annotation.Nullable;
import android.util.AttributeSet;
import android.view.View;
import android.view.animation.LinearInterpolator;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class RunBall extends View {
    private ValueAnimator mAnimator;// Time flow

    private List<Ball> mBalls;// Ball objects
    private Paint mPaint;// Main paint
    private Paint mHelpPaint;// Auxiliary line paint
    private Point mCoo;// Coordinate system

    private float defaultR = 10;// Default ball radius
    private int defaultColor = Color.BLUE;// Default ball color
    private float defaultVX = 10;// Default ball x-direction velocity
    private float defaultF = 0.95f;// Collision loss
    private float defaultVY = -10;// Default ball y-direction velocity
    private float defaultAY = 0.1f;// Default ball acceleration

    private float mMaxX = 500;// X maximum value
    private float mMinX = 10;// X minimum value
    private float mMaxY = 400;// Y maximum value
    private float mMinY = 10;// Y minimum value

    private LinearInterpolator li;

    public RunBall(Context context) {
        this(context, null);
    }

    public RunBall(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init() {
        mCoo = new Point(10, 10);
        // Initialize balls

        // Initialize paint
        mPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        mBalls = new ArrayList<>();
        //Ball ball = initBall();
        for(int i=0;i<100;i++) {
            Ball ball = initBall();
            mBalls.add(ball); // Add one
        }
        mHelpPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        mHelpPaint.setColor(Color.BLACK);
        mHelpPaint.setStyle(Paint.Style.FILL);
        mHelpPaint.setStrokeWidth(3);

        // Initialize time flow ValueAnimator
        mAnimator = ValueAnimator.ofFloat(-1, 0);
        mAnimator.setRepeatCount(-1);
        mAnimator.setDuration(1000);
        mAnimator.setRepeatMode(ValueAnimator.REVERSE);
        mAnimator.setInterpolator(new LinearInterpolator());
        // Developer options required, enable "Animator duration scale" to non-off state.
        //
        // The reason is ValueAnimator is Android's option for animation,
        // because all Animators have an Interpolator (default is AccelerateDecelerateInterpolator),
        // and the value passed to setInterpolator is TimeInterpolator, i.e., "Animator duration scale"
        mAnimator.addUpdateListener(animation -> {
            // android.util.Log.d("JUMIN", "addUpdateListener "+animation.getAnimatedValue());
            updateBall();// Update ball position
            invalidate();
        });
        mAnimator.start();

    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        canvas.save();
        canvas.translate(mCoo.x, mCoo.y);
        drawBalls(canvas, mBalls);
        canvas.restore();
    }

    /**
     * Draw ball collection
     *
     * @param canvas
     * @param balls  Ball collection
     */
    private void drawBalls(Canvas canvas, List<Ball> balls) {
        for (Ball ball : balls) {
            //ball.color =randomRGB();
            mPaint.setColor(ball.color);
            canvas.drawCircle(ball.x, ball.y, ball.r, mPaint);
        }
    }

    /**
     * Update balls
     */
    private void updateBall() {
        for (int i = 0; i < mBalls.size(); i++) {
            Ball ball = mBalls.get(i);

            ball.x += ball.vX;
            ball.y += ball.vY;
            ball.vY += ball.aY;
            ball.vX += ball.aX;
            if (ball.x > mMaxX - ball.r) {
//                Ball newBall = ball.clone();// Create a new ball with the same info
//                //newBall.r = newBall.r / 2;
//                newBall.vX = -newBall.vX;
//                newBall.vY = -newBall.vY;
//                mBalls.add(newBall);

                ball.x = mMaxX - ball.r;
                ball.vX = -ball.vX;// * defaultF;
                ball.color =randomRGB();// Change color
                //ball.r = ball.r / 2;
            }
            if (ball.x < mMinX - ball.r) {
//                Ball newBall = ball.clone();
//                //newBall.r = newBall.r / 2;
//                newBall.vX = -newBall.vX;
//                newBall.vY = -newBall.vY;
//                mBalls.add(newBall);

                ball.x = mMinX + ball.r;
                ball.vX = -ball.vX ;//* defaultF;
                ball.color =randomRGB();

                //ball.r = ball.r / 2;
            }
            if (ball.y > mMaxY - ball.r) {

                ball.y = mMaxY - ball.r;
                ball.vY = -ball.vY;// * defaultF;
                ball.color =randomRGB();
            }
            if (ball.y < mMinY + ball.r) {
                ball.y = mMinY + ball.r;
                ball.vY = -ball.vY ;//* defaultF;
                ball.color =randomRGB();
            }
        }
    }


//    @Override
//    public boolean onTouchEvent(MotionEvent event) {
//        switch (event.getAction()) {
//            case MotionEvent.ACTION_DOWN:
//                mAnimator.start();
//                break;
//            case MotionEvent.ACTION_UP:
////                mAnimator.pause();
//                break;
//        }
//        return true;
//    }

    private Ball initBall() {
        float vx = new Random().nextFloat();
        Ball mBall = new Ball();
        mBall.color = defaultColor;
        mBall.r = defaultR;
        mBall.vX = defaultVX*vx;
        mBall.vY = defaultVY*vx;
        mBall.aY = defaultAY;
        Random random = new Random();
        mBall.x = random.nextInt(600);
        mBall.y = random.nextInt(300);
        return mBall;
    }


    /**
     * Return random color
     *
     * @return Random color
     */
    public static int randomRGB() {
        Random random = new Random();
        int r = 30 + random.nextInt(200);
        int g = 30 + random.nextInt(200);
        int b = 30 + random.nextInt(200);
        return Color.rgb( r, g, b);
    }
}
