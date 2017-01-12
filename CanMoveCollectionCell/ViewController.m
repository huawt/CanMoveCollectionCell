//
//  ViewController.m
//  CanMoveCollectionCell
//
//  Created by huawt on 2017/1/12.
//  Copyright © 2017年 huawt. All rights reserved.
//

#import "ViewController.h"


#import "CollectionViewCell.h"

//屏幕尺寸
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, strong) NSIndexPath *oldIndexPath;
@property (nonatomic, strong) NSIndexPath *moveIndexPath;
@property (nonatomic, strong) UIView *snapshotView;
@end

@implementation ViewController

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.minimumLineSpacing = 5;
        flowLayout.minimumInteritemSpacing = 5;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 64, kScreenWidth, kScreenHeight - 64 - 49) collectionViewLayout:flowLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        
        [_collectionView registerNib:[UINib nibWithNibName:@"CollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"CollectionViewCell"];
    }
    return _collectionView;
}
- (NSMutableArray *)dataArr
{
    if (!_dataArr) {
        _dataArr = @[].mutableCopy;
        for (NSInteger i = 0; i < 100; i++) {
            [_dataArr addObject:[UIColor colorWithRed:arc4random()%255/255.0f green:arc4random()%255/255.0f blue:arc4random()%255/255.0f alpha:1]];
        }
    }
    return _dataArr;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.collectionView];
    
    UILongPressGestureRecognizer*longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlelongGesture:)];
    
    [self.collectionView addGestureRecognizer:longPress];
    
}

- (void)handlelongGesture:(UILongPressGestureRecognizer*)longPress
{
    if([[[UIDevice currentDevice]systemVersion]floatValue] <9.0) {
        [self action:longPress];
    }else{
        [self iOS9_Action:longPress];
    }
}

#pragma mark - iOS9 之后的方法
- (BOOL)collectionView:(UICollectionView*)collectionView canMoveItemAtIndexPath:(NSIndexPath*)indexPath
{
    // 返回YES允许row移动
    return YES;
}

- (void)collectionView:(UICollectionView*)collectionView moveItemAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath
{
    //取出移动row数据
    id color =self.dataArr[sourceIndexPath.row];
    //从数据源中移除该数据
    [self.dataArr removeObject:color];
    //将数据插入到数据源中的目标位置
    [self.dataArr insertObject:color atIndex:destinationIndexPath.row];
}

- (void)iOS9_Action:(UILongPressGestureRecognizer*)longPress
{
    
    switch(longPress.state) {
        case UIGestureRecognizerStateBegan:
        {//手势开始
            
            //判断手势落点位置是否在row上
            NSIndexPath*indexPath = [self.collectionView indexPathForItemAtPoint:[longPress locationInView:self.collectionView]];
            if(indexPath ==nil) {
                break;
            }
            UICollectionViewCell*cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            [self.view bringSubviewToFront:cell];
            //iOS9方法 移动cell
            [self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
        }break;
            
        case UIGestureRecognizerStateChanged:
        {// 手势改变
            // iOS9方法 移动过程中随时更新cell位置
            [self.collectionView updateInteractiveMovementTargetPosition:[longPress locationInView:self.collectionView]];
        }break;
            
        case UIGestureRecognizerStateEnded:
        {// 手势结束
            // iOS9方法 移动结束后关闭cell移动
            [self.collectionView endInteractiveMovement];
        }break;
            
        default://手势其他状态
            [self.collectionView cancelInteractiveMovement];
            break;
    }
}

#pragma mark - iOS9 之前的方法
- (void)action:(UILongPressGestureRecognizer*)longPress
{
    switch(longPress.state) {
            
        case UIGestureRecognizerStateBegan:
        {// 手势开始
            //判断手势落点位置是否在row上
            NSIndexPath*indexPath = [self.collectionView indexPathForItemAtPoint:[longPress locationInView:self.collectionView]];
            self.oldIndexPath= indexPath;
            if(indexPath ==nil) {
                break;
            }
            UICollectionViewCell*cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            // 使用系统的截图功能,得到cell的截图视图
            UIView*snapshotView = [cell snapshotViewAfterScreenUpdates:NO];
            snapshotView.frame= cell.frame;
            [self.view addSubview:self.snapshotView=snapshotView];
            // 截图后隐藏当前cell
            cell.hidden=YES;
            CGPoint currentPoint = [longPress locationInView:self.collectionView];
            [UIView animateWithDuration:0.25 animations:^{
                snapshotView.transform= CGAffineTransformMakeScale(1.05,1.05);
                snapshotView.center= currentPoint;
            }];
        }break;
            
        case UIGestureRecognizerStateChanged:
        {// 手势改变
            //当前手指位置 截图视图位置随着手指移动而移动
            CGPoint currentPoint = [longPress locationInView:self.collectionView];
            self.snapshotView.center= currentPoint;
            // 计算截图视图和哪个可见cell相交
            for(UICollectionViewCell*cell in self.collectionView.visibleCells) {
                // 当前隐藏的cell就不需要交换了,直接continue
                if([self.collectionView indexPathForCell:cell] == self.oldIndexPath) {
                    continue;
                }
                // 计算中心距
                CGFloat space = sqrtf(pow(self.snapshotView.center.x- cell.center.x,2) + powf(self.snapshotView.center.y- cell.center.y,2));
                // 如果相交一半就移动
                if(space <=self.snapshotView.bounds.size.width/2) {
                    self.moveIndexPath= [self.collectionView indexPathForCell:cell];
                    //移动 会调用willMoveToIndexPath方法更新数据源
                    [self.collectionView moveItemAtIndexPath:self.oldIndexPath toIndexPath:self.moveIndexPath];
                    //设置移动后的起始indexPath
                    self.oldIndexPath=self.moveIndexPath;
                    break;
                }
            }
        } break;
            
        default:
        {// 手势结束和其他状态
            UICollectionViewCell*cell = [self.collectionView cellForItemAtIndexPath:self.oldIndexPath];
            // 结束动画过程中停止交互,防止出问题
            self.collectionView.userInteractionEnabled=NO;
            // 给截图视图一个动画移动到隐藏cell的新位置
            [UIView animateWithDuration:0.25 animations:^{
                self.snapshotView.center= cell.center;
                self.snapshotView.transform= CGAffineTransformMakeScale(1.0,1.0);
            }completion:^(BOOL finished) {
                // 移除截图视图,显示隐藏的cell并开始交互
                [self.snapshotView removeFromSuperview];
                cell.hidden=NO;
                self.collectionView.userInteractionEnabled=YES;
            }];
        }break;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataArr.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
    cell.testLabel.text = @(indexPath.item).stringValue;
    cell.backgroundColor = [self.dataArr objectAtIndex:indexPath.item];
    return cell;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kScreenWidth / 5 - 30 / 5, kScreenWidth / 5 - 30 / 5);
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, 5, 5, 5);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
