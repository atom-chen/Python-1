#include "HelloWorldScene.h"
#include "CardSprite.h"
USING_NS_CC;

CCScene* HelloWorld::scene()
{
    CCScene *scene = CCScene::create();
    HelloWorld *layer = HelloWorld::create();
    scene->addChild(layer);
    return scene;
}
#pragma mark 初始化
bool HelloWorld::init()
{
    if (!CCLayer::init())
    {
        return false;
    }
    //窗体大小
    size = CCDirector::sharedDirector()->getVisibleSize();
    //背景颜色设置
    CCLayerColor * bg = CCLayerColor::create(ccc4(180, 170, 160,255));
    addChild(bg);
    
    //总分数
    CCMenuItemFont * font = CCMenuItemFont::create("总分数：");
    font->setFontSize(30);
    font->setPosition(ccp(100, 420));
    addChild(font,3);
    //显示总分数值
    label = CCLabelTTF::create();
    label->setPosition(ccp(200, 420));
    label->setFontSize(30);
    addChild(label,3);
    //生成卡片
    createCardSprite(size);
    //生成卡片数字
    autoCreateCardNumber();
    CCDirector::sharedDirector()->getTouchDispatcher()->addTargetedDelegate(this, 0, false);
    return true;
}
#pragma mark 触摸
 bool HelloWorld::ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent)
{
    CCPoint point = pTouch->getLocation();
    firstX = point.x;
    firstY = point.y;
    return true;
}
 void HelloWorld::ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent)
{
    //结束点位置
    CCPoint point = pTouch->getLocation();
    endX = firstX - point.x;
    endY = firstY - point.y;
    
    //如果结束点的x值大于结束点的Y值  左右滑动   小于 上下滑动  +5 是偏移量
    if (abs(endX) > abs(endY)) {
        if (endX+5 > 0) {
            if(doLeft())
            {
                autoCreateCardNumber();
                doCheakGameOver();
            }
        }
        else{
           if( doRight())
           {
               autoCreateCardNumber();
               doCheakGameOver();
           }
        }
    }
    else{
        if (endY+5 > 0) {
           if( doDown())
           {
               autoCreateCardNumber();
               doCheakGameOver();
           }
        }
        else
        {
           if( doUp())
           {
               autoCreateCardNumber();
               doCheakGameOver();
           }
        }
    }
   
}

#pragma mark 游戏是否能够继续进行
void HelloWorld::doCheakGameOver()
{
    bool isGamerOver = true;
    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            
            
            if (cardArr[x][y]->getNumber() == 0 ||
                (x > 0 && (cardArr[x][y]->getNumber() == cardArr[x-1][y]->getNumber()))||
                (x < 3 && (cardArr[x][y]->getNumber() == cardArr[x+1][y]->getNumber()))||
                (y > 0 && (cardArr[x][y]->getNumber() == cardArr[x][y-1]->getNumber()))||
                (y < 3 && (cardArr[x][y]->getNumber() == cardArr[x][y+1]->getNumber()))){
                isGamerOver = false;
            }
        }
    }
    if (isGamerOver) {
        CCMessageBox("GameOver", "游戏结束，重新开始");
        CCDirector::sharedDirector()->replaceScene(CCTransitionCrossFade::create(1, HelloWorld::scene()));
    }
}
#pragma mark 随机出现的数组 2
void HelloWorld::autoCreateCardNumber()
{
    int i = CCRANDOM_0_1()*4;
    int j = CCRANDOM_0_1()*4;
    
    if (cardArr[i][j]->getNumber()>0) {
        autoCreateCardNumber();
    }
    else{
        cardArr[i][j]->setNumber(CCRANDOM_0_1()*10<1?4:2);
    }
}

#pragma mark 生成4*4 方格
void HelloWorld::createCardSprite(CCSize size)
{
    int lon = (size.width -28)/4; //113
    
    //4*4
    for (int j = 0 ;j<4; j++) {
        for (int i = 0; i<4; i++) {
            CardSprite * card = CardSprite::createCardSprite(0, lon, lon, lon*j+20, lon*i+20+size.height/6);
            addChild(card);
            
            cardArr[j][i]= card;
        }
    }
}
#pragma mark 上下左右滑动
bool HelloWorld::doLeft()
{
    bool  isdo = false;
    for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
            
            for (int x1 = x + 1; x1 < 4; x1++) {
                if (cardArr[x1][y]->getNumber() > 0) {
                    if (cardArr[x][y]->getNumber() <= 0) {
                        cardArr[x][y]->setNumber(cardArr[x1][y]->getNumber());
                        cardArr[x1][y]->setNumber(0);
                        
                        x--;
                        isdo = true;
                    }else if (cardArr[x][y]->getNumber() == cardArr[x1][y]->getNumber())
                    {
                         cardArr[x][y]->setNumber(cardArr[x][y]->getNumber()*2);
                         cardArr[x1][y]->setNumber(0);
                        
                        score += cardArr[x][y]->getNumber();
                        char f[10];
                        sprintf(f, "%d",score);
                        label->setString(f);
                        
                        //label->setString(CCString::createWithFormat("%i",score)->getCString());
                        isdo = true;
                    }
                    break;
                }
            }
        }
    }
    return isdo;
}
bool HelloWorld::doRight()
{
    bool  isdo = false;
    for (int y = 0; y < 4; y++) {
        for (int x = 3; x >= 0; x--) {
            
            for (int x1 = x - 1; x1 >=0; x1--) {
                if (cardArr[x1][y]->getNumber() > 0) {
                    if (cardArr[x][y]->getNumber() <= 0) {
                        cardArr[x][y]->setNumber(cardArr[x1][y]->getNumber());
                        cardArr[x1][y]->setNumber(0);
                        
                        x++;
                        isdo = true;
                    }else if (cardArr[x][y]->getNumber() == cardArr[x1][y]->getNumber())
                    {
                        cardArr[x][y]->setNumber(cardArr[x][y]->getNumber()*2);
                        cardArr[x1][y]->setNumber(0);
                        
                        score += cardArr[x][y]->getNumber();
                        char f[10];
                        sprintf(f, "%d",score);
                        label->setString(f);
                        //label->setString(CCString::createWithFormat("%i",score)->getCString());
                        
                        isdo = true;
                    }
                    break;
                }
            }
        }
    }
    return isdo;
}
bool HelloWorld::doUp()
{
    bool  isdo = false;
    for (int x = 0; x < 4; x++) {
        for (int y = 3; y >= 0; y--) {
            
            for (int y1 = y - 1; y1 >=0; y1--) {
                if (cardArr[x][y1]->getNumber() > 0) {
                    if (cardArr[x][y]->getNumber() <= 0) {
                        cardArr[x][y]->setNumber(cardArr[x][y1]->getNumber());
                        cardArr[x][y1]->setNumber(0);
                        
                        y++;
                        isdo = true;
                    }else if (cardArr[x][y]->getNumber() == cardArr[x][y1]->getNumber())
                    {
                        cardArr[x][y]->setNumber(cardArr[x][y]->getNumber()*2);
                        cardArr[x][y1]->setNumber(0);
                        
                        score += cardArr[x][y]->getNumber();
                        char f[10];
                        sprintf(f, "%d",score);
                        label->setString(f);
                        //label->setString(CCString::createWithFormat("%i",score)->getCString());
                        isdo = true;
                    }
                    break;
                }
            }
        }
    }
    return isdo;
}
bool HelloWorld::doDown()
{
    bool  isdo = false;
    for (int x = 0; x < 4; x++) {
        for (int y = 0; y< 4; y++) {
            
            for (int y1 = y +1; y1 <4; y1++) {
                if (cardArr[x][y1]->getNumber() > 0) {
                    if (cardArr[x][y]->getNumber() <= 0) {
                        cardArr[x][y]->setNumber(cardArr[x][y1]->getNumber());
                        cardArr[x][y1]->setNumber(0);
                        
                        y--;
                        isdo = true;
                    }else if (cardArr[x][y]->getNumber() == cardArr[x][y1]->getNumber())
                    {
                        cardArr[x][y]->setNumber(cardArr[x][y]->getNumber()*2);
                        cardArr[x][y1]->setNumber(0);
                        
                        score += cardArr[x][y]->getNumber();
                        char f[10];
                        sprintf(f, "%d",score);
                        label->setString(f);
                        //label->setString(CCString::createWithFormat("%i",score)->getCString());
                        
                        isdo = true;
                    }
                    break;
                }
            }
        }
    }
    return isdo;
}
