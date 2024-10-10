---
title: All about PingFang on iOS 18
excerpt: 关于新的可变苹方，所有你想知道的（且我知道的）。
---

>  ## 前传
>
>  -  [关于 iOS 18 的新苹方 VF – 知乎](https://zhuanlan.zhihu.com/p/703335162)
>  -  [关于苹方可变的说明 – 微信公众号](https://mp.weixin.qq.com/s/sVS5OVp_sGJ9Esr1_c1Wuw)

## 背景

从 iOS 18（及同期 macOS Sequoia, watchOS 10 等）beta 开始，许多更新的用户觉察到中文 UI 字体似乎变粗变小了，一些开发者也注意到系统字体 (`-[UIFont systemFontOfSize:]`, `-apple-system`) 的中文部分可以更粗了。

首先需要明确，系统字体并不直接对应某个字体资源，而是一组复杂的 fallback 机制。在中文环境下，西文调用 San Francisco (`.SFUI`/`.SFNS`)，中文调用苹方；其他环境下对汉字及一些符号的 fallback 顺序有所不同。SF 从一开始就拥有较为完整的字重支持；Text 支持 Light—Heavy，Display 支持 Ultralight—Black[^intro-sf]；后改为可变字体，Text 也支持了全套字重；再后来 Text 和 Display 合并到同一个字体资源中，充分使用 `opsz` 轴和 `trak` 表。

Another Ref [^intro-sf].

[^intro-sf]: [Introducing the New System Fonts — WWDC 2015](https://docs.huihoo.com/apple/wwdc/2015/804_introducing_the_new_system_fonts.pdf)

Another note [^note2]

[^note2]: Hello, foot notes!
