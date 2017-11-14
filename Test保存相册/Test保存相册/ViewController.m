//
//  ViewController.m
//  Test保存相册
//
//  Created by weiman on 2017/11/8.
//  Copyright © 2017年 weiman. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>

#define  AppName @"测试相册"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveImageToPhotos:(id)sender {
    UIImage * image = [UIImage imageNamed:@"乔巴"];
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted) {
        //因为家长控制, 导致应用无法方法相册(跟用户的选择没有关系)
        NSLog(@"因为系统原因, 无法访问相册");
    }else if (status == PHAuthorizationStatusDenied){
        //用户拒绝当前应用访问相册(用户当初点击了"不允许")
        NSLog(@"用户拒绝访问相册");
    }else if (status == PHAuthorizationStatusAuthorized){
        //用户允许当前应用访问相册(用户当初点击了"好")
        [self saveImageToPhotosWithImage:image];
    }else if (status == PHAuthorizationStatusNotDetermined){
        // 用户还没有做出选择,弹窗请求用户权限
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                //用户点击了允许
              [self saveImageToPhotosWithImage:image];
            }
        }];
    }
}

//方法一
-(void)saveImageToPhotosWithImage:(UIImage *)image{
    if (!image) {
        NSLog(@"图片为空");
        return;
    }else{
        // PHAsset : 一个资源, 比如一张图片\一段视频
        // PHAssetCollection : 一个相簿
        // PHAsset的标识, 利用这个标识可以找到对应的PHAsset对象(图片对象)
        
        //如果想对"相册"进行修改(增删改), 那么修改代码必须放在[PHPhotoLibrary sharedPhotoLibrary]的performChanges方法的block中
        __weak ViewController * weakSelf = self;
        __block NSString *assetLocalIdentifier = nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            //1.保存图片A到“相机胶卷”中
            assetLocalIdentifier = [PHAssetCreationRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                NSLog(@"保存图片失败");
                return;
            }
            
            //2.获得相册
            PHAssetCollection * createdAssetCollection = [weakSelf createAssetCollection];
            if (createdAssetCollection==nil) {
                NSLog(@"创建相册失败");
                return;
            }
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                
                //3.添加"相机胶卷"中的图片A到"相簿"D中
                //获得图片
                PHAsset * asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetLocalIdentifier] options:nil].lastObject;
                //添加图片到相簿中的请求
                PHAssetCollectionChangeRequest * request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdAssetCollection];
                
                //添加图片到相簿
                [request addAssets:@[asset]];
                
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    NSLog(@"保存图片成功");
                }else{
                    NSLog(@"保存图片失败");
                }
                
            }];
            
        }];
        
    }
}

//获取系统相册
-(PHAssetCollection *)createAssetCollection{
    
    //从已经存在的相册中查找这个应用对应的相簿
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection * assetCollection in assetCollections) {
        if ([assetCollection.localizedTitle isEqualToString:AppName]) {
            return assetCollection;
        }
    }

    //没有找到对应的相簿,就要创建这个相簿
    NSError * error = nil;
    // PHAssetCollection的标识, 利用这个标识可以找到对应的PHAssetCollection对象(相簿对象)
     __block NSString *assetCollectionLocalIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        //创建相簿的请求
        assetCollectionLocalIdentifier = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:AppName].placeholderForCreatedAssetCollection.localIdentifier;
        
    } error:&error];
    
    //如果有错误信息
    if (error) {
        return nil;
    }
    //获得刚才创建的相簿
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetCollectionLocalIdentifier] options:nil].lastObject;
}

@end











