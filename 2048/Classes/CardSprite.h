//
//  CardSprite.h
//  2048
//
//  Created by len on 14-9-29.
//
//

#ifndef ___048__CardSprite__
#define ___048__CardSprite__

#include <iostream>
#include "cocos2d.h"
USING_NS_CC;

class CardSprite:public CCSprite
{
private:
    int number;
    CCLabelTTF * labelTTFCardNumber;
    CCLayerColor * layerColorBG;
    
public:
    static CardSprite * createCardSprite(int numbers,int width,int heigth,float CardSpriteX,float CardSpriteY);
    virtual bool init();
    CREATE_FUNC(CardSprite);
    
    
    void setNumber(int num);
    int  getNumber();
    
    void enemyInit(int numbers,int width,int heigth,float CardSpriteX,float CardSpriteY);
    
};
#endif /* defined(___048__CardSprite__) */
