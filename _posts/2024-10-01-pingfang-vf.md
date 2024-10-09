---
title: PingFangUI-VF
---

已知 iOS 18 (macOS Sequoia, watchOS 11, ...) 在 UI 中使用了更粗的苹方。至此，系统中存在两份苹方，一者继承自原先的苹方，但被降级为用户可安装字体，在首次请求时下载；一者作为系统字体，使用私有格式。前者依然为六个字重，不过新增了澳门地区字形（苹方-澳）；后者则为可变字体，不仅新增了澳门地区字形，还包含了与 SF 统一的 9 个字重。

## 新的苹方

私有 UI 字体（下称苹方 UI）储存于系统私有库 FontServices.framework/Versions/Current/Resources/Reserved/PingFangUI.ttc。虽然总体格式仍为 SFNT (Collection)，但实际储存轮廓的表为 Apple 新创的私有 `hvgl`。该新格式并没有公开任何文档，也无任何工具支持——Twitter 上对该格式的讨论也仅限于一些猜测——甚至更神秘的是，将该字体复制出原有目录后，系统也不识别该字体。许多 Unity 开发者注意到了中文字体显示异常：Unity 并不调用系统 API，而是使用了自己内置的渲染引擎，无法解析这一新的表。

>   关于 `hvgl` 的讨论，可以参见 [\[1\]](https://zhuanlan.zhihu.com/p/703335162), [\[2\]](https://zhuanlan.zhihu.com/p/720942264) 等。

根据其他表可知，苹方 UI 是可变字体（有合法的 `fvar` 等表），且形式上应为 TrueType 轮廓（据 `maxp` 表及头部魔术字）。虽然不能解析 `hvgl`，但可以通过系统 API 间接获取（也许有损的）轮廓数据。根据这些数据，可以重建 `glyf` 和 `gvar` 表，从而生成可被其他环境识别的字体。

>   ## 使用系统 API 获取字形数据
>
>   iOS/macOS 的字体处理由其图形库 CoreGraphics 直接负责；FontServices 是 CoreGraphics 的子库。尽管如此，CoreGraphics 并没有公开太多字体相关 API，而是由 CoreText 封装后提供给开发者。
>
>   使用以下的代码载入 苹方 UI：
>
>   ```swift
>   let url = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/FontServices.framework/Versions/A/Resources/Reserved/PingFangUI.ttc")
>   let desc = (CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as! [CTFontDescriptor]).last {desc in
>        return CFEqual(CTFontDescriptorCopyAttribute(desc, kCTFontNameAttribute), ".PingFangWatchSC-Medium" as CFString)
>   }!
>
>   let font = CTFontCreateWithFontDescriptor(desc, 1080, nil)
>   ```
>
>   在这里使用了 `PingFangWatchSC-Medium`：这是因为它的 `avar` 表对于每一个轴是双射的（即一对一的映射，并且在这里定义域和值域都是 \[−1, 1\]，能够取到设计空间所有的点）；且 0 对应到 0，性质良好。代码中的字号 `1080` 可以改成任何合理的正数，但这里选择字体的 UPM（`PingFangWatchSC-Medium` 的 UPM 并非 1000，因为苹果有意将其显示得小一些），以便后续获得点的坐标不用再缩放。
>
>   检查 `fvar` 表（或者用 CoreText 提供的其他 API），可知它有三个轴：
>
>   | 轴 tag | 最小值 | 默认值 | 最大值 |
>   | --- | --- | --- | --- |
>   | `WDTH` | 1 | 500 | 1000 |
>   | `wght` | 100 | 500 | 1000 |
>   | `HGHT` | 1 | 500 | 1000 |
>
>   但我们并不知道它有哪些母版 (master)。事实上，每个字形的母版数和母版在可变空间中的位置都可以不一样；但是通常设计师不会做得太复杂。只有完整检查 `gvar` 表或者 `CFF2` 表才能知道这些信息——很残酷，苹方 UI 用的是 `hvgl`。除了各轴默认值意味的默认母版（这里是中粗体）以外，根据苹方 UI 的实际显示效果，认为再选定各个轴的端点处的实例 (instance) 作为母版是合理的。
>
>   ```swift
>   let masterDesc = CTFontDescriptorCreateWithAttributes([kCTFontVariationAttribute: <#轴值字典#>,
>                                                        kCTFontOpticalSizeAttribute: "none"] as CFDictionary)
>   let masterFont = CTFontCreateCopyWithAttributes(font, 1080, nil, masterDesc)
>
>   var glyphID = <#字形 ID#> as CGGlyph
>   let glyphPath = CTFontCreatePathForGlyph(masterFont, glyphID, nil)
>
>   var advance = CGSize()
>   CTFontGetAdvancesForGlyphs(masterFont, .horizontal, &glyphID, &advance, 1)
>   ```
>
>   使用 `kCTFontOpticalSizeAttribute: "none"` 来禁用苹方 UI 所含有的 `trak` 表根据字号调整字间距 (tracking)，以得到如实的前进宽度 (advance width)。后续如何将宽度和轮廓数据重建为 `glyf` 和 `gvar` 表，请使用其他工具或者自行编写工具，本文将不讨论。

## 细节讨论

许多升级了 iOS 18 的用户注意到新的苹方在笔画交接处会有毛刺，比如「口」的左上角和右上角。这是由于未对齐像素边界的轮廓会使用半透明的颜色作平滑处理；苹方 UI 笔画轮廓未被合并，两次填充导致部分重叠区域颜色变深。这种现象在 DPI 较低的设备上尤为明显（因为单个像素更大）。事实上，SF 也存在这种现象，例如「P」的左上角，只是没有苹方明显。Apple 应该知晓这个问题，但这可能是他们故意为之。为了缓解这一现象，本项目提供的字体已经合并了部分轮廓。

>   ## 保证母版兼容下尽量合并轮廓
>
>   母版兼容即，任取一个母版，对于剩下的每一个母版，其轮廓数目与所取母版相同，且每一对在相同下标的轮廓的点数相同、点类型依次相同（TrueType 为二次曲线，点类型分为在轮廓上的点和不在轮廓上的点）。这是母版间插值的前提，也是制作可变字体的先决条件。
>
>   我们已知系统提供的苹方字形轮廓是母版兼容的。要保证合并若干笔画后的字形仍然母版兼容，可以通过以下步骤：
>
>   对于每一个母版……
>
>   1.  任取一对（两个不相同的）下标的轮廓，检查他们是否都有相交。如果任意一个母版下不相交，舍弃这一对下标，取下一对。
>   2.  合并这一对下标的轮廓（取并集）。检查该并集是否是母版兼容的。如果不是，舍弃这一对下标，取下一对。
>   3.  对每一个母版，删除这一对下标的轮廓，加入合并后的轮廓。
>   4.  重复 1–3，直到所有的下标都被检查过。
>
>   >   在下标选择有规律时，可以省略一些不必要的检查。
>
>   这种方法可以保证合并后的字形仍然是母版兼容的。但这种方法受轮廓布尔运算库限制，比如一些库取交集后会更变轮廓的起始点，导致母版不兼容；这可能要求手动调整轮廓的起始点，并移除不必要的点。另外在实际操作中，作为一个实体的未必是一个轮廓：例如「O」由两个轮廓组成，如果要与斜线合并（「Ø」），其两个圆圈不能单独参与合并，而应该作为一个整体。

但事实上，苹方 UI 质量欠佳。除了主观设计外，系统提供的轮廓也有大量冗余点，且布点相当诡异；部分应当对齐的点未对齐，或者横不平竖不直。值得注意的是，该版的粗体与本该同源的[华康金刚黑](https://www.dynacw.com.cn/king/)的粗体设计相差甚远，且对于可变字体笔画拆分的处理也完全不一致。考虑到常规字重也与先前的静态苹方不同，在此有理由猜测这一版本的苹方 VF 未经由华康设计，且使用了基于骨架的设计和储存方式。华康金刚黑可被看作由华康发行的（非 UI）苹方的商业版本。当前 (2024/10/1) 所有地区字形都提供了 Ultralight 至 Ultrablack 的 12 个静态字重，而日本地区字形额外提供了 Std 字符集的 VF（但仅从 Ultralight 至 Semibold）。苹方 UI 与华康金刚黑相比，仅极细/Ultralight 至中粗/Semibold 的六个实例字重能大致符合；在更粗的字重选择上，两者看不出直接联系。

## 内容差异和已知问题

-   西文保持原样（除了修正部分母版字形位置错误）。请不要直接使用苹方的自带西文，而始终与其他字体（例如 SF）配套使用。
-   将原本的宽度轴 `WDTH` 规范为 `wdth`，并将最小/默认/最大值标定为 80/100/120。
-   移除了非规范高度轴 `HGHT`。该轴在日常中并不实用，且可以通过字重与宽度轴的插值获得。
-   如上述所说，合并了部分轮廓，以减少毛刺。同时修改部分字形的设计。
-   半宽体部分字的轮廓异常（俗称炸了/烂字），受影响的字约两千个。这是因为合并字形轮廓后，尚未修正它们的起始点。

## 使用许可

本项目提供的苹方 UI 文件仅供学习和研究使用，不得用于任何商业用途。若您希望再次分发本项目提供的文件，请一并附上本自述文件（或其来源）。
