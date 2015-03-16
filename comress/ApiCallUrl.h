//
//  ApiCallUrl.h
//  comress
//
//  Created by Diffy Romano on 30/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#ifndef comress_ApiCallUrl_h
#define comress_ApiCallUrl_h

static NSString * AFkey_allowInvalidCertificates = @"allowInvalidCertificates";


static NSString *api_activationUrl = @"http://fmit.com.sg/comressmainservice/AddressManager.svc/json/GetUrlAddress/?group=";

static NSString *server_url = @"http://comresstest.selfip.com/ComressMWCF/"; //temporary

static NSString *api_login = @"User.svc/ComressLogin";

static NSString *api_logout = @"User.svc/Logout?sessionId=";

static NSString *api_post_send = @"Messaging/Post.svc/UploadPost";

static NSString *api_comment_send = @"Messaging/Comment.svc/UploadComment";

static NSString *api_send_images = @"Messaging/PostImage.svc/UploadImageWithBase64";

static NSString *api_download_blocks = @"PublicSetup.svc/GetBlocks";

static NSString *api_download_user_blocks = @"Job/Block.svc/GetBlocksByUser";

static NSString *api_update_device_token = @"User.svc/UpdateDeviceToken?";

static NSString *api_download_posts = @"Messaging/Post.svc/GetPosts";

static NSString *api_download_comments = @"Messaging/Comment.svc/GetComments";

static NSString *api_download_images = @"Messaging/PostImage.svc/GetImages";

static NSString *api_download_comment_noti = @"Messaging/CommentNoti.svc/GetCommentNotis";

static NSString *api_upload_comment_noti = @"Messaging/CommentNoti.svc/UpdateStatusAfterRead";

static NSString *api_update_status_after_read = @"Messaging/CommentNoti.svc/UpdateStatusAfterRead";

static NSString *api_update_post_status = @"Messaging/Post.svc/UpdatePostActionStatus";




//routine

static NSString *api_download_checklist = @"Job/Setup.svc/GetCheckLists";

static NSString *api_download_checkarea = @"Job/Setup.svc/GetCheckAreas";

static NSString *api_download_scan_checklist_blk =  @"Job/Setup.svc/GetScanCheckListBlks";

static NSString *api_download_scan_checklist = @"PublicSetup.svc/GetScanCheckLists";

static NSString *api_download_jobs = @"/Job/Setup.svc/GetJobs";


#endif



