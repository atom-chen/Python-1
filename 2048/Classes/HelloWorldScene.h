#ifndef __HELLOWORLD_SCENE_H__
#define __HELLOWORLD_SCENE_H__

#include "cocos2d.h"
#include "CardSprite.h"
USING_NS_CC;

class HelloWorld : public cocos2d::CCLayer
{
public:
    CCSize size;
    virtual bool init();  
    static cocos2d::CCScene* scene();
    CREATE_FUNC(HelloWorld);
    
    
public:
    //触摸开始，结束、
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent);
   
    //判断是左右上下滑动
    bool doLeft();
    bool doRight();
    bool doUp();
    bool doDown();
    //自动生成卡片上的数字
    void autoCreateCardNumber();
    //判断游戏是否继续运行
    void doCheakGameOver();
    //注册 4*4方格 
    void createCardSprite(CCSize size);
private:
    int firstX,firstY,endX,endY;
    
    //显示总分数
    int score;
    CCLabelTTF * label;
    //4*4 数组
    CardSprite * cardArr[4][4];
};

#endif // __HELLOWORLD_SCENE_H__
