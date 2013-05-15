WINAssist是一个AutoHotKey脚本。脚本中功能模块参考了一些优秀的AutoHotKey脚本，如：[HK4WIN](http://www.songruihua.com/hk4win.html)，[链接转换](http://ahk.5d6d.net/viewthread.php?tid=2025)，[screenlock ](http://www.appinn.com/Lock-Screen-Appinn/)，[HDDMonitor](http://www.autohotkey.com/board/topic/16501-hdd-activity-monitoring-led/)，[PCMeter](http://fures.hu/my_ahk_updates/PCMeter.ahk)，[KDE Style](http://www.autohotkey.com/docs/scripts/EasyWindowDrag_\(KDE\).htm)，[DesktopSwitch](http://myhotkey.googlecode.com/svn/trunk/bin/%E5%A4%9A%E5%B1%8F%E5%B9%95%E5%88%87%E6%8D%A2/)，[NiftyWindows](http://www.autohotkey.com/board/topic/2460-niftywindows/)，[ClipJump](http://avi-win-tips.blogspot.in/p/clipjump.html)等。在此谨向以上脚本的作者表示感谢！
    
本脚本实现的功能：
  
* 收藏
根据需要在[Favorites]标签下编辑，格式:
    1. :目录名|收藏项目名称=路径
    2. 收藏项目名称=路径
    3. 分割‘-’

* 任务列表    
根据需要在[todolist]标签下编辑，每条任务之后换行

* 其它快捷键及功能对照表
<table>
 <tr>
  <td>Win + Alt + C[~L]</td>
  <td>打开(C~L)盘</td>
  <td>113</td>
 </tr>
 <tr>
  <td>Win + I</td>
  <td>资源管理器中反选</td>
  <td>117</td>
 </tr>
 <tr>
  <td>Win + N</td>
  <td>新建文件夹（文件名为当前系统时间）</td>
  <td>118</td>
 </tr>
 <tr>
  <td>Ctrl + H</td>
  <td>隐藏/显示隐藏文件</td>
  <td>120</td>
 </tr>
 <tr>
  <td>Win + Ctrl + H</td>
  <td>隐藏/显示隐藏文件、系统文件</td>
  <td>120</td>
 </tr>
 <tr>
  <td>鼠标手势（中键）</td>
  <td>资源管理器鼠标手势</td>
  <td>122</td>
 </tr>
 <tr>
  <td>Win + F</td>
  <td>启动Everything文件名实时搜索</td>
  <td>203</td>
 </tr>
 <tr>
  <td>Win + Space</td>
  <td>打开Everything但不会在动搜索当前文件夹</td>
  <td>204</td>
 </tr>
 <tr>
  <td>鼠标手势（中键）</td>
  <td>IE浏览器鼠标手势</td>
  <td>215</td>
 </tr>
 <tr>
  <td>右下角 滚轮</td>
  <td>音量调节</td>
  <td>301</td>
 </tr>
 <tr>
  <td>右下角 中键</td>
  <td>静音</td>
  <td>301</td>
 </tr>
 <tr>
  <td>Ctrl + F</td>
  <td>资源管理器中按Ctrl+F，打开Everything并自动搜索当前文件夹</td>
  <td>304</td>
 </tr>
 <tr>
  <td>左下角 滚轮</td>
  <td>3D窗口切换窗口</td>
  <td>310</td>
 </tr>
 <tr>
  <td>Win + Ctrl + C</td>
  <td>复制所选文件的路径</td>
  <td>330</td>
 </tr>
 <tr>
  <td>RCtrl + LCtrl</td>
  <td>定时关机</td>
  <td>333</td>
 </tr>
 <tr>
  <td>LAlt + 左键</td>
  <td>任意位置移动窗口</td>
  <td>334</td>
 </tr>
 <tr>
  <td>LAlt + 右键</td>
  <td>任意位置缩放窗口</td>
  <td>334</td>
 </tr>
 <tr>
  <td>标题栏向上滚轮</td>
  <td>最大化窗口</td>
  <td>335</td>
 </tr>
 <tr>
  <td>标题栏向下滚轮</td>
  <td>恢复窗口</td>
  <td>336</td>
 </tr>
 <tr>
  <td>任务栏向下滚轮</td>
  <td>最小化所有窗口</td>
  <td>336</td>
 </tr>
 <tr>
  <td>F3</td>
  <td>用google搜索所选关键词</td>
  <td>338</td>
 </tr>
 <tr>
  <td>Shift + F3</td>
  <td>用百度搜索所选关键词</td>
  <td>338</td>
 </tr>
 <tr>
  <td>鼠标手势（中键）</td>
  <td>照片查看器鼠标手势</td>
  <td>555</td>
 </tr>
 <tr>
  <td>中键(资源管理器中)</td>
  <td>用gvim、potplayer打开文件</td>
  <td>556</td>
 </tr>
 <tr>
  <td>Win + Ctrl + Z</td>
  <td>链接转化，迅雷、快车、旋风地址转换为普通地址</td>
  <td>557</td>
 </tr>
 <tr>
  <td>Win + K</td>
  <td>锁屏</td>
  <td>558</td>
 </tr>
 <tr>
  <td>Ctrl + Alt + H</td>
  <td>老板键</td>
  <td>559</td>
 </tr>
 <tr>
  <td>Alt + 1~4</td>
  <td>切换桌面</td>
  <td>560</td>
 </tr>
 <tr>
  <td>Ctrl + Alt + 1~4</td>
  <td>将激活的窗口发送到桌面</td>
  <td>560</td>
 </tr>
 <tr>
  <td>Win + C</td>
  <td>在当前位置打开cmd</td>
  <td>561</td>
 </tr>
 <tr>
  <td>Win + 滚轮</td>
  <td>调整窗口透明度&nbsp; 步距 1</td>
  <td>562</td>
 </tr>
 <tr>
  <td>Win + Shift + 滚轮</td>
  <td>调整窗口透明度&nbsp; 步距 10</td>
  <td>562</td>
 </tr>
 <tr>
  <td>Win + Ctrl + 左键</td>
  <td>窗口穿透（部分）</td>
  <td>562</td>
 </tr>
 <tr>
  <td>Win + Ctrl + 中键</td>
  <td>窗口穿透（全部）</td>
  <td>562</td>
 </tr>
 <tr>
  <td>Win + 中键</td>
  <td>取消窗口透明</td>
  <td>562</td>
 </tr>
 <tr>
  <td>Win + Ctrl + T</td>
  <td>取消所有窗口透明</td>
  <td>562</td>
 </tr>
 <tr>
  <td>按下鼠标右键 + 滚轮</td>
  <td>切换窗口</td>
  <td>563</td>
 </tr>
 <tr>
  <td></td>
  <td>HDDMonitor开关</td>
  <td>564</td>
 </tr>
 <tr>
  <td>Ctrl + V</td>
  <td>ClipJump粘贴模式，在此模式下，按一次Ctrl + X 取消，两次从剪切板删除当前内容，三次删除剪切板全部内容；Ctrl + V向后切换剪切板内容；Ctrl + C向前切换剪切板内容；Ctrl + S将当前剪切板加到windows剪切板中；Ctrl + Space固定一个剪切板位置</td>
  <td>565</td>
 </tr>
 <tr>
  <td>Ctrl + Alt + X</td>
  <td>复制当前打开的目录路径</td>
  <td>565</td>
 </tr>
  <tr>
  <td>Ctrl + Alt + C</td>
  <td>复制当前选择的文件路径</td>
  <td>565</td>
 </tr>
 <tr>
  <td>中键单击窗口</td>
  <td>窗口最小化</td>
  <td></td>
 </tr>
 <tr>
  <td>Ctrl + Alt + Z</td>
  <td>截图</td>
  <td></td>
 </tr>
 <tr>
  <td>Alt+Ctrl+Shift+D</td>
  <td>取消定时关机</td>
  <td></td>
 </tr>
 <tr>
  <td>标题栏中键</td>
  <td>卷起窗口</td>
  <td></td>
 </tr>
 <tr>
  <td>Win + 左键</td>
  <td>窗口置顶开关</td>
  <td></td>
 </tr>
 <tr>
  <td>Win + Ctrl + R</td>
  <td>取消所有窗口卷起</td>
  <td></td>
 </tr>
 <tr>
  <td>Alt + 0（零）</td>
  <td>退出脚本</td>
  <td></td>
 </tr>
 <tr>
  <td>Win + W</td>
  <td>天气预报</td>
  <td></td>
 </tr>
</table>
本人使用本脚本已有一年多，所以一些设置是针对本人使用习惯，你可以自行根据自己习惯更改设置。[Favorites]、[softpath]标签下的路径需要自己更改，一些功能也仅限于在win7中使用。


