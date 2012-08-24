/*
 * This file is part of the JTRevealSidebar package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol JTRevealSidebarV2Delegate <NSObject>

@optional
- (UIView *)viewForLeftSidebar;
- (UIView *)viewForRightSidebar;
- (UIView *)view;
- (void)toggleLeftSidebar:(id)sender;

- (void)leftSideBarWillOpen:(id)sender;
- (void)leftSideBarOpened:(id)sender;
- (void)leftSideBarWillClose:(id)sender;
- (void)leftSideBarClosed:(id)sender;


@end
