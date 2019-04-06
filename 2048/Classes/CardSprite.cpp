//
//  CardSprite.cpp
//  2048
//
//  Created by len on 14-9-29.
//
//

#include "CardSprite.h"

#pragma mark 初始化4*4方格
CardSprite * CardSprite::createCardSprite(int numbers,int width,int heigth,float CardSpriteX,float CardSpriteY)
{
    CardSprite * emeny = new CardSprite();
    if (emeny && emeny->init()) {
        emeny->autorelease();
        emeny->enemyInit(numbers, width, heigth, CardSpriteX, CardSpriteY);
        return emeny;
    }
    CC_SAFE_DELETE(emeny);
    return NULL;
}
 bool CardSprite::init()
{
    if (!CCSprite::init()) {
        return false;
    }
    return true;
}

#pragma mark 设置方格中数字的大小及颜色
void CardSprite::setNumber(int num)
{
    number = num;
    if (number >= 0) {
        labelTTFCardNumber->setFontSize(60);
    }
    if (number >= 16) {
        labelTTFCardNumber->setFontSize(40);
    }
    if (number >= 128) {
        labelTTFCardNumber->setFontSize(28);
    }
    if (number >= 1024) {
        labelTTFCardNumber->setFontSize(24);
    }
    
    
    if (number == 0) {
        layerColorBG ->setColor(ccc3(200, 190, 180));
    }
    if (number == 2) {
        layerColorBG ->setColor(ccc3(240, 220, 220));
    }
    if (number == 4) {
        layerColorBG ->setColor(ccc3(240, 220, 200));
    }
    if (number == 8) {
        layerColorBG ->setColor(ccc3(240, 180, 120));
    }
    if (number == 16) {
        layerColorBG ->setColor(ccc3(240, 140, 90));
    }
    if (number == 32) {
        layerColorBG ->setColor(ccc3(240, 120, 60));
    }
    if (number == 64) {
        layerColorBG ->setColor(ccc3(240, 90, 60));
    }
    if (number == 128) {
        layerColorBG ->setColor(ccc3(240, 90, 60));
    }
    if (number == 256) {
        layerColorBG ->setColor(ccc3(240, 200, 70));
    }
    if (number == 512) {
        layerColorBG ->setColor(ccc3(240, 200, 70));
    }
    if (number == 1024) {
        layerColorBG ->setColor(ccc3(0, 130, 0));
    }
    if (number == 2048) {
        layerColorBG ->setColor(ccc3(0, 130, 0));
    }
    
    
    
    if (number > 0) {
        labelTTFCardNumber->setString(CCString::createWithFormat("%i",number)->getCString());
    }else
    {
        labelTTFCardNumber->setString("");
    }
}
#pragma mark 得到数字
int CardSprite::getNumber()
{
    return number;
}
#pragma mark  游戏背景颜色 方格的样式等
void  CardSprite::enemyInit(int numbers,int width,int heigth,float CardSpriteX,float CardSpriteY)
{
    number = numbers;
    layerColorBG = CCLayerColor::create(ccc4(200, 190, 180, 255),width-15,heigth-15);
    layerColorBG->setPosition(ccp(CardSpriteX,CardSpriteY));
    
    
    if (numbers > 0) {
        
        labelTTFCardNumber =CCLabelTTF::create(CCString::createWithFormat("%i",number)->getCString(), "Arial", 40);
        labelTTFCardNumber->setPosition(ccp(layerColorBG->getContentSize().width/2,layerColorBG->getContentSize().height/2));
        layerColorBG->addChild(labelTTFCardNumber);
    }
    else{
        labelTTFCardNumber = CCLabelTTF::create("", "Arial", 40);
        labelTTFCardNumber->setPosition(ccp(layerColorBG->getContentSize().width/2,layerColorBG->getContentSize().height/2));
        layerColorBG->addChild(labelTTFCardNumber);
    }
    this->addChild(layerColorBG);
}
