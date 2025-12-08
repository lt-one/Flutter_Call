"""
通话详单查看器 - 主程序
一比一复刻中国联通通话记录界面
"""
import flet as ft
import flet.canvas as cv
from database import CallLogDatabase
from datetime import datetime
import time
import math
import base64


def create_star_canvas(size=24, color="#000000", stroke_width=2.5):
    """创建五角星Canvas"""
    # 计算五角星的顶点坐标
    center_x, center_y = size / 2, size / 2
    outer_radius = size * 0.4
    inner_radius = size * 0.18
    
    points = []
    for i in range(10):
        angle = math.pi * i / 5 - math.pi / 2
        radius = outer_radius if i % 2 == 0 else inner_radius
        x = center_x + radius * math.cos(angle)
        y = center_y + radius * math.sin(angle)
        points.append((x, y))
    
    # 创建路径
    path_elements = [cv.Path.MoveTo(points[0][0], points[0][1])]
    for i in range(1, len(points)):
        path_elements.append(cv.Path.LineTo(points[i][0], points[i][1]))
    path_elements.append(cv.Path.Close())
    
    return cv.Canvas(
        [
            cv.Path(
                path_elements,
                paint=ft.Paint(
                    stroke_width=stroke_width,
                    style=ft.PaintingStyle.STROKE,
                    color=color,
                    stroke_cap=ft.StrokeCap.ROUND,
                    stroke_join=ft.StrokeJoin.ROUND
                )
            )
        ],
        width=size,
        height=size
    )


def create_arrow_canvas(size=22, color="#000000", stroke_width=2.5):
    """创建返回箭头Canvas"""
    # 箭头路径: < 形状
    center_y = size / 2
    start_x = size * 0.6
    end_x = size * 0.3
    arrow_height = size * 0.4
    
    return cv.Canvas(
        [
            cv.Path(
                [
                    cv.Path.MoveTo(start_x, center_y - arrow_height),
                    cv.Path.LineTo(end_x, center_y),
                    cv.Path.LineTo(start_x, center_y + arrow_height),
                ],
                paint=ft.Paint(
                    stroke_width=stroke_width,
                    style=ft.PaintingStyle.STROKE,
                    color=color,
                    stroke_cap=ft.StrokeCap.ROUND,
                    stroke_join=ft.StrokeJoin.ROUND
                )
            )
        ],
        width=size,
        height=size
    )


def create_fingerprint_pattern(width=350, height=100):
    """创建指纹纹路装饰图案 - 真正的损失函数(双曲线)曲线族"""
    shapes = []
    
    # 使用双曲线 y = k/x 的形状 (L型)
    # 坐标系: 以Canvas左下角为原点 (0, height)
    # 实际上我们希望曲线向右上角弯曲
    
    # 我们构建一组 y = k/x 曲线
    # k越大，曲线越远离原点(左下)，越靠近右上
    # "最里面的线条在最右上角" -> i=0时 k最大
    # "往左下角扩散" -> i增大时 k减小
    
    num_lines = 18
    
    # 调整参数以适应 350x100 的画布
    # 画布左下角是 (0, 100)
    
    origin_x = 0
    origin_y = height + 10 # 上移原点(原+40)，让曲线底部往上收
    
    num_lines = 22 
    
    for i in range(num_lines):
        # i=0 (最里/右上): k大
        # i=21 (最外/左下): k小
        
        progress = i / (num_lines - 1)
        
        # k值范围调整
        # 增大max_k以覆盖右上角
        # width=350, origin_y=140 -> target k > 350*140 = 49000
        max_k = 52000  # 足够大，确保最内层覆盖右上角
        min_k = 1500   # 保持最外层位置
        
        # 非线性插值
        k = min_k + (max_k - min_k) * ((1 - progress) ** 1.3)
        
        # 颜色再变浅: 透明度降低
        # 反转渐变: 外层(progress接近1)深, 内层(progress接近0)浅
        # 内层保持约 0.04, 外层增加到 0.08
        opacity = 0.03 + 0.03 * progress 
        stroke = 0.6 + 0.1 * (1 - progress)
        
        # 生成路径点
        path_elements = []
        points_count = 60
        
        # x的范围
        x_at_top = k / origin_y
        start_x = max(0, x_at_top) 
        end_x = width + 80 # 延伸更远
        
        first_point = True
        valid_points = 0
        
        for j in range(points_count + 1):
            curr_x = start_x + (end_x - start_x) * (j / points_count)
            
            if curr_x > 0:
                curve_y = k / curr_x
            else:
                continue
                
            screen_y = origin_y - curve_y
            
            # 宽容的边界检查
            if -50 <= screen_y <= height + 50:
                if first_point:
                    path_elements.append(cv.Path.MoveTo(curr_x, screen_y))
                    first_point = False
                else:
                    path_elements.append(cv.Path.LineTo(curr_x, screen_y))
                valid_points += 1
        
        if valid_points > 1:
            shapes.append(
                cv.Path(
                    path_elements,
                    paint=ft.Paint(
                        color=ft.Colors.with_opacity(opacity, ft.Colors.WHITE),
                        stroke_width=stroke,
                        style=ft.PaintingStyle.STROKE,
                        stroke_cap=ft.StrokeCap.ROUND,
                        stroke_join=ft.StrokeJoin.ROUND
                    )
                )
            )
    
    return cv.Canvas(
        shapes,
        width=width,
        height=height
    )


def create_calendar_icon(size, color, bg_color):
    """绘制自定义日历图标"""
    border_width = 1.5  # 边框细一点
    content_width = 2.2 # 耳朵和横线粗一点
    
    shapes = []
    
    # 1. 主体方框 (圆角矩形)
    # 留出顶部耳朵的空间
    box_top = size * 0.25
    box_height = size * 0.75
    
    shapes.append(
        cv.Rect(
            x=size * 0.1,
            y=box_top,
            width=size * 0.8,
            height=box_height,
            border_radius=4,
            paint=ft.Paint(
                color=bg_color, # 填充浅粉色
                style=ft.PaintingStyle.FILL,
            )
        )
    )
    
    # 边框
    shapes.append(
        cv.Rect(
            x=size * 0.1,
            y=box_top,
            width=size * 0.8,
            height=box_height,
            border_radius=4,
            paint=ft.Paint(
                color=color,
                stroke_width=border_width, # 边框细一点
                style=ft.PaintingStyle.STROKE,
            )
        )
    )
    
    # 2. 顶部两个耳朵 (竖线)
    ear_height = size * 0.2
    ear_y_start = size * 0.15
    
    for x_pos in [size * 0.3, size * 0.7]:
        shapes.append(
            cv.Path(
                [
                    cv.Path.MoveTo(x_pos, ear_y_start),
                    cv.Path.LineTo(x_pos, ear_y_start + ear_height)
                ],
                paint=ft.Paint(
                    color=color,
                    stroke_width=content_width, # 耳朵粗一点
                    style=ft.PaintingStyle.STROKE,
                    stroke_cap=ft.StrokeCap.ROUND
                )
            )
        )
        
    # 3. 中间横线 (一长一短)
    # 长横线
    line1_y = box_top + box_height * 0.35
    shapes.append(
        cv.Path(
            [
                cv.Path.MoveTo(size * 0.25, line1_y),
                cv.Path.LineTo(size * 0.75, line1_y)
            ],
            paint=ft.Paint(
                color=color,
                stroke_width=content_width, # 横线粗一点
                style=ft.PaintingStyle.STROKE,
                stroke_cap=ft.StrokeCap.ROUND
            )
        )
    )
    
    # 短横线
    line2_y = box_top + box_height * 0.65
    shapes.append(
        cv.Path(
            [
                cv.Path.MoveTo(size * 0.25, line2_y),
                cv.Path.LineTo(size * 0.55, line2_y)
            ],
            paint=ft.Paint(
                color=color,
                stroke_width=content_width, # 横线粗一点
                style=ft.PaintingStyle.STROKE,
                stroke_cap=ft.StrokeCap.ROUND
            )
        )
    )

    return cv.Canvas(shapes, width=size, height=size)


def create_search_icon(size, color, stroke_width=2.0):
    """绘制自定义放大镜图标: 大圈短柄"""
    # 圈
    radius = size * 0.35
    center_x = size * 0.4
    center_y = size * 0.4
    
    # 柄
    handle_length = size * 0.25
    handle_start_x = center_x + radius * 0.7 # 45度角
    handle_start_y = center_y + radius * 0.7
    handle_end_x = handle_start_x + handle_length
    handle_end_y = handle_start_y + handle_length
    
    shapes = [
        # 圈
        cv.Circle(
            x=center_x,
            y=center_y,
            radius=radius,
            paint=ft.Paint(
                style=ft.PaintingStyle.STROKE,
                stroke_width=stroke_width,
                color=color
            )
        ),
        # 柄
        cv.Path(
            [
                cv.Path.MoveTo(handle_start_x, handle_start_y),
                cv.Path.LineTo(handle_end_x, handle_end_y)
            ],
            paint=ft.Paint(
                style=ft.PaintingStyle.STROKE,
                stroke_width=stroke_width,
                color=color,
                stroke_cap=ft.StrokeCap.ROUND
            )
        )
    ]
    
    return cv.Canvas(shapes, width=size, height=size)


def create_phone_icon(size, color, is_outgoing=True):
    """绘制自定义空心话筒图标 (带箭头区分主叫/被叫)"""
    # 使用新的SVG路径
    svg_content = """<svg t="1764858099888" class="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg" p-id="5925" width="200" height="200"><path d="M217.856 94.677333c-36.608 14.762667-60.928 38.485333-96.597333 83.2-88.618667 111.232-9.386667 332.8 194.730666 535.210667l10.581334 10.368c192 184.576 434.986667 264.533333 527.701333 184.064l3.029333-2.816-1.450666 1.194667a249.301333 249.301333 0 0 0 64.042666-77.994667c33.152-64 24.149333-130.858667-41.173333-182.954667-94.037333-75.008-157.184-77.568-219.434667-20.48l-6.997333 6.570667-18.005333 17.834667c-7.808-1.621333-19.882667-7.338667-34.730667-16.896-29.610667-19.114667-66.517333-50.901333-108.586667-92.586667-41.941333-41.642667-74.069333-78.208-93.312-107.605333l-3.882666-6.101334a120.448 120.448 0 0 1-12.245334-24.832l-0.938666-3.413333 18.133333-17.92 6.613333-6.954667c57.472-61.738667 54.912-124.373333-20.650666-217.642666-51.328-63.36-109.653333-83.328-166.826667-60.245334z m99.925333 113.493334l11.221334 14.08c37.546667 48.682667 37.888 64.853333 16.384 89.258666l-8.32 8.874667-21.12 20.821333c-45.482667 45.056-25.258667 102.314667 41.856 181.205334l14.08 16.085333 15.232 16.682667 8.106666 8.533333 16.981334 17.621333 18.176 18.261334 9.258666 9.130666 18.090667 17.450667 17.408 16.298667c5.717333 5.205333 11.306667 10.24 16.810667 15.104l16.213333 13.909333c79.616 66.56 137.216 86.570667 182.698667 41.685333l21.034666-20.992 5.546667-5.248c24.277333-22.186667 39.296-25.301333 80.725333 3.968l12.586667 9.258667 14.250667 11.093333c31.232 24.917333 34.261333 47.573333 18.602666 77.781334a165.845333 165.845333 0 0 1-26.88 36.608l-7.253333 7.338666-5.546667 5.12-5.333333 4.650667c-14.421333 14.293333-69.888 15.658667-141.184-7.722667-90.709333-29.781333-189.994667-92.074667-280.746667-182.101333-177.109333-175.658667-241.408-355.413333-188.16-422.272 26.453333-33.194667 43.648-49.92 61.653334-57.173333 19.285333-7.808 38.570667-1.194667 67.626666 34.688z" fill="#000000" p-id="5926"></path></svg>"""
    
    svg_b64 = base64.b64encode(svg_content.encode('utf-8')).decode('utf-8')
    
    handset_image = ft.Image(
        src_base64=svg_b64,
        width=size,
        height=size,
        color=color,
        fit=ft.ImageFit.CONTAIN
    )
    
    # 绘制箭头
    scale = size / 24.0
    stroke_width = 2.5 * scale # 加粗线条 (原2.0)
    arrow_paint = ft.Paint(
        style=ft.PaintingStyle.STROKE, 
        stroke_width=stroke_width, 
        color=color, 
        stroke_cap=ft.StrokeCap.ROUND, 
        stroke_join=ft.StrokeJoin.ROUND
    )
    
    shapes = []
    
    if is_outgoing:
        # 主叫 (绿色): 箭头从话筒顶部水平指向右边
        # 话筒顶部 (听筒) 大概在 (17, 5) 附近 (基于24网格)
        # 往左移动一点，更靠近话筒: x减小
        
        start_x, start_y = 15 * scale, 6 * scale # 顶部，左移
        end_x, end_y = 24 * scale, 6 * scale     # 水平向右，长度保持
        
        shapes.append(cv.Path([
            cv.Path.MoveTo(start_x, start_y), 
            cv.Path.LineTo(end_x, end_y)
        ], paint=arrow_paint))
        
        # 箭头头 (在右端)
        shapes.append(cv.Path([
            cv.Path.MoveTo(20 * scale, 3 * scale), # 上翼
            cv.Path.LineTo(end_x, end_y),           # 尖端
            cv.Path.LineTo(20 * scale, 9 * scale)  # 下翼
        ], paint=arrow_paint))
    else:
        # 被叫 (蓝色): 箭头在左上/顶侧，向内指 (指向话筒)
        # 同样整体往左/下移一点
        
        start_x, start_y = 20 * scale, 2 * scale # 起点 (右上)
        end_x, end_y = 13 * scale, 9 * scale  # 终点 (指向话筒中心，更深入一点)
        
        shapes.append(cv.Path([
            cv.Path.MoveTo(start_x, start_y), 
            cv.Path.LineTo(end_x, end_y) 
        ], paint=arrow_paint))
        # 箭头头 (在中心端)
        shapes.append(cv.Path([
            cv.Path.MoveTo(13.7 * scale, 4.1 * scale), # 修正坐标以匹配箭头形状
            cv.Path.LineTo(end_x, end_y),
            cv.Path.LineTo(17.9 * scale, 8.3 * scale)  # 修正坐标以匹配箭头形状
        ], paint=arrow_paint))
        
    arrow_canvas = cv.Canvas(shapes, width=size, height=size)
    
    return ft.Stack([
        handset_image,
        arrow_canvas
    ], width=size, height=size)


def create_sort_icons(size=20, color_up="#353535", color_down="#a3a3a3"):
    """绘制排序图标: 两个三角形，底对底"""
    width = size * 0.6 # 整体宽度
    height = size      # 整体高度
    
    triangle_width = width * 0.8 # 三角形底边宽度
    triangle_height = height * 0.28 # 单个三角形高度 (稍微调低一点)
    gap = height * 0.1 # 间距
    
    center_x = width / 2
    center_y = height / 2
    
    shapes = []
    
    # 上箭头 (尖朝上)
    shapes.append(
        cv.Path(
            [
                cv.Path.MoveTo(center_x, center_y - gap/2 - triangle_height),
                cv.Path.LineTo(center_x - triangle_width/2, center_y - gap/2),
                cv.Path.LineTo(center_x + triangle_width/2, center_y - gap/2),
                cv.Path.Close()
            ],
            paint=ft.Paint(style=ft.PaintingStyle.FILL, color=color_up)
        )
    )
    
    # 下箭头 (尖朝下)
    shapes.append(
        cv.Path(
            [
                cv.Path.MoveTo(center_x, center_y + gap/2 + triangle_height),
                cv.Path.LineTo(center_x - triangle_width/2, center_y + gap/2),
                cv.Path.LineTo(center_x + triangle_width/2, center_y + gap/2),
                cv.Path.Close()
            ],
            paint=ft.Paint(style=ft.PaintingStyle.FILL, color=color_down)
        )
    )
    
    return cv.Canvas(shapes, width=width, height=height)


def create_dropdown_icon(size=12, color="#999999"):
    """绘制下拉图标: 等边三角形，指向下"""
    width = size
    # 等边三角形高度 = sqrt(3)/2 * 边长 ≈ 0.866 * 边长
    height = size * 0.866
    
    center_x = width / 2
    center_y = width / 2 # 画布中心
    
    # 三角形中心调整，使其在画布垂直居中
    y_offset = (width - height) / 2
    
    shapes = [
        cv.Path(
            [
                cv.Path.MoveTo(center_x, y_offset + height),       # 下顶点 (尖)
                cv.Path.LineTo(0, y_offset),                       # 左上
                cv.Path.LineTo(width, y_offset),                   # 右上
                cv.Path.Close()
            ],
            paint=ft.Paint(style=ft.PaintingStyle.FILL, color=color)
        )
    ]
    
    return cv.Canvas(shapes, width=width, height=width)  # 画布必须是正方形以容纳旋转等操作(虽然这里没旋转)


class CallLogApp:
    """通话记录应用主类"""
    
    def __init__(self, page: ft.Page):
        self.page = page
        self.page.theme = ft.Theme(
            font_family="Microsoft YaHei",
            scrollbar_theme=ft.ScrollbarTheme(
                thumb_visibility=False,
                track_visibility=False,
                thickness=0,
                interactive=False
            )
        )  # 设置全局字体和隐藏滚动条
        self.db = CallLogDatabase()
        
        # 从数据库加载顶部电话号码，默认为 175****8164
        self.top_phone_number = self.db.get_config("top_phone_number", "175****8164")
        
        # 点击计数器(用于连续点击检测)
        self.click_count = 0
        self.last_click_time = 0
        
        # 当前选择的月份
        self.current_month = "12月"
        self.current_year = "2025"
        
        # 选中的记录ID列表
        self.selected_logs = []
        
        # 初始化页面配置
        self.setup_page()
        
        # 初始化数据
        self.init_data()
        
        # 构建UI
        self.build_ui()
    
    def setup_page(self):
        """配置页面属性"""
        self.page.title = "详单查询"
        self.page.theme_mode = ft.ThemeMode.LIGHT
        self.page.padding = 0
        # 注意: Page本身不支持gradient,所以保持纯色背景
        self.page.bgcolor = "#eb4c46"  # 中国联通红色背景(渐变起始色)
        
        # 设置沉浸式状态栏 (主界面: 红色背景，白色图标)
        self.page.system_overlay_style = ft.SystemOverlayStyle(
            status_bar_color=ft.Colors.TRANSPARENT, # 透明，让背景色透出来
            status_bar_icon_brightness=ft.Brightness.LIGHT, # 状态栏图标为白色
            system_navigation_bar_color="#f9f9f9", # 底部导航栏背景色
            system_navigation_bar_icon_brightness=ft.Brightness.DARK, # 底部导航栏图标为深色
            system_navigation_bar_divider_color=ft.Colors.TRANSPARENT
        )
        
        self.page.window.width = 400
        self.page.window.height = 800
    
    def init_data(self):
        """初始化数据"""
        # 检查是否有数据，如果没有则创建示例数据
        logs = self.db.get_all_logs()
        if not logs:
            self.db.init_sample_data()
    
    def on_phone_number_click(self, e):
        """电话号码点击事件 - 连续点击3次触发添加功能"""
        current_time = time.time()
        
        # 如果距离上次点击超过1秒，重置计数
        if current_time - self.last_click_time > 1:
            self.click_count = 0
        
        self.click_count += 1
        self.last_click_time = current_time
        
        if self.click_count == 3:
            # 触发添加通话记录对话框
            self.show_log_dialog() # 使用通用的日志对话框
            self.click_count = 0

    def on_top_number_long_press(self, e):
        """顶部号码长按事件 - 编辑号码"""
        self.show_top_number_dialog()

    def show_top_number_dialog(self):
        """显示编辑顶部号码对话框"""
        phone_input = ft.TextField(
            label="顶部显示号码",
            value=self.top_phone_number,
            text_align=ft.TextAlign.CENTER
        )

        def close_dialog(e):
            dialog.open = False
            self.page.update()

        def save_number(e):
            self.top_phone_number = phone_input.value
            self.db.set_config("top_phone_number", self.top_phone_number)
            # 更新UI显示
            self.top_phone_text.value = self.top_phone_number
            self.show_snackbar("号码修改成功", ft.Colors.GREEN_400)
            close_dialog(e)

        dialog = ft.AlertDialog(
            title=ft.Text("修改顶部号码"),
            content=ft.Container(content=phone_input, height=80),
            actions=[
                ft.TextButton("取消", on_click=close_dialog),
                ft.TextButton("保存", on_click=save_number)
            ],
            actions_alignment=ft.MainAxisAlignment.END
        )
        self.page.overlay.append(dialog)
        dialog.open = True
        self.page.update()
    
    def on_call_log_long_press(self, log_id: int):
        """通话记录长按事件"""
        def handler(e):
            self.show_edit_menu(log_id)
        return handler
    
    def show_log_dialog(self, log_id: int = None):
        """显示添加/编辑通话记录对话框"""
        is_edit = log_id is not None
        title = "编辑通话记录" if is_edit else "添加通话记录"
        
        current_log = None
        if is_edit:
            logs = self.db.get_all_logs()
            current_log = next((log for log in logs if log['id'] == log_id), None)
            if not current_log:
                return

        # 默认值设置
        default_date = datetime.now().strftime("%m.%d")
        default_time = datetime.now().strftime("%H:%M")
        
        # 输入字段
        date_input = ft.TextField(label="日期 (MM.DD)", value=current_log['call_date'] if is_edit else default_date, expand=True)
        weekday_input = ft.TextField(label="星期", value=current_log.get('weekday', '') if is_edit else "", expand=True, hint_text="留空自动计算")
        time_input = ft.TextField(label="接通时间 (HH:MM)", value=current_log['connect_time'] if is_edit else default_time, expand=True)
        
        phone_input = ft.TextField(label="对方号码", value=current_log['phone_number'] if is_edit else "", expand=True, keyboard_type=ft.KeyboardType.PHONE)
        location_input = ft.TextField(label="归属地", value=current_log['location'] if is_edit else "福建福州", expand=True)
        
        is_outgoing_switch = ft.Switch(label="主叫 (关闭为被叫)", value=bool(current_log['is_outgoing']) if is_edit else True)
        
        duration_input = ft.TextField(label="通话时长(秒)", value=str(current_log['call_duration']) if is_edit else "0", expand=True, keyboard_type=ft.KeyboardType.NUMBER)
        billing_input = ft.TextField(label="计费分钟数", value=str(current_log['billing_minutes']) if is_edit else "1", expand=True, keyboard_type=ft.KeyboardType.NUMBER)
        fee_input = ft.TextField(label="通话费用", value=f"{current_log['call_fee']:.2f}" if is_edit else "0.00", expand=True, keyboard_type=ft.KeyboardType.NUMBER)
        
        def close_dialog(e):
            dialog.open = False
            self.page.update()
        
        def save_log(e):
            try:
                duration = int(duration_input.value)
                billing = int(billing_input.value)
                fee = float(fee_input.value)
                
                call_data = {
                    'phone_number': phone_input.value,
                    'call_type': '高清语音',
                    'location': location_input.value,
                    'connect_time': time_input.value,
                    'call_duration': duration,
                    'billing_minutes': billing,
                    'call_fee': fee,
                    'call_date': date_input.value,
                    'call_time': time_input.value, # 暂时使用接通时间作为call_time
                    'is_hd_voice': 1,
                    'is_outgoing': 1 if is_outgoing_switch.value else 0,
                    'weekday': weekday_input.value
                }
                
                if is_edit:
                    self.db.update_call_log(log_id, call_data)
                    self.show_snackbar("修改成功", ft.Colors.GREEN_400)
                else:
                    self.db.add_call_log(call_data)
                    self.show_snackbar("添加成功", ft.Colors.GREEN_400)
                
                close_dialog(e)
                self.refresh_call_list()
                
            except ValueError:
                self.show_snackbar("请输入有效的数值", ft.Colors.RED_400)
        
        dialog = ft.AlertDialog(
            title=ft.Text(title),
            content=ft.Container(
                content=ft.Column([
                    ft.Row([date_input, weekday_input]),
                    time_input,
                    is_outgoing_switch,
                    ft.Row([phone_input, location_input]),
                    ft.Row([duration_input, billing_input]),
                    fee_input
                ], tight=True, spacing=10, scroll=ft.ScrollMode.AUTO),
                width=350,
                height=450
            ),
            actions=[
                ft.TextButton("取消", on_click=close_dialog),
                ft.TextButton("保存", on_click=save_log)
            ],
            actions_alignment=ft.MainAxisAlignment.END
        )
        
        self.page.overlay.append(dialog)
        dialog.open = True
        self.page.update()
    
    def show_edit_menu(self, log_id: int):
        """显示编辑/删除菜单"""
        def close_menu(e):
            bottom_sheet.open = False
            self.page.update()
        
        def edit_log(e):
            close_menu(e)
            self.show_log_dialog(log_id) # 使用通用对话框
        
        def delete_log(e):
            self.db.delete_call_log(log_id)
            self.show_snackbar("删除成功", ft.Colors.GREEN_400)
            close_menu(e)
            self.refresh_call_list()
        
        bottom_sheet = ft.BottomSheet(
            content=ft.Container(
                content=ft.Column([
                    ft.ListTile(
                        leading=ft.Icon(ft.Icons.EDIT),
                        title=ft.Text("编辑"),
                        on_click=edit_log
                    ),
                    ft.ListTile(
                        leading=ft.Icon(ft.Icons.DELETE, color=ft.Colors.RED_400),
                        title=ft.Text("删除", color=ft.Colors.RED_400),
                        on_click=delete_log
                    ),
                    ft.Container(height=10),
                    ft.TextButton(
                        "取消",
                        on_click=close_menu,
                        style=ft.ButtonStyle(
                            color=ft.Colors.GREY_700
                        )
                    )
                ], tight=True),
                padding=20
            )
        )
        
        self.page.overlay.append(bottom_sheet)
        bottom_sheet.open = True
        self.page.update()
    
    def show_snackbar(self, message: str, bgcolor: str):
        """显示提示信息"""
        snack = ft.SnackBar(
            content=ft.Text(message, color="#fbfffd"),
            bgcolor=bgcolor
        )
        self.page.overlay.append(snack)
        snack.open = True
        self.page.update()
    
    def refresh_call_list(self):
        """刷新通话记录列表"""
        # 重新获取数据
        logs = self.db.get_all_logs()
        total_fee = self.db.get_total_fee()
        
        # 更新费用显示
        self.fee_text.value = f"{total_fee:.2f}元"
        
        # 更新通话记录列表
        self.call_list.controls.clear()
        for log in logs:
            self.call_list.controls.append(self.create_call_item(log))
        
        # 添加底部提示："没有更多了"
        if logs:  # 只有当有记录时才显示
            self.call_list.controls.append(
                ft.Column([
                    # 分割线
                    ft.Container(
                        height=0.5,
                        bgcolor="#eeeeee",
                        margin=ft.margin.symmetric(horizontal=15)
                    ),
                    # "没有更多了"文字
                    ft.Container(
                        content=ft.Text(
                            "没有更多了",
                            size=13,
                            color="#999999",
                            weight=ft.FontWeight.W_500
                        ),
                        alignment=ft.alignment.center,
                        padding=ft.padding.symmetric(vertical=15)
                    )
                ], spacing=0)
            )
        
        self.page.update()

    def show_more_menu(self):
        """显示更多菜单"""
        def clear_logs_click(e):
            bs.open = False
            self.page.update()
            
            # 显示二次确认对话框
            def confirm_clear(e):
                self.db.clear_all_logs()
                confirm_dialog.open = False
                self.page.update()
                self.refresh_call_list()
                self.show_snackbar("通话记录已清空", ft.Colors.GREEN_400)

            def cancel_clear(e):
                confirm_dialog.open = False
                self.page.update()

            confirm_dialog = ft.AlertDialog(
                title=ft.Text("清空记录"),
                content=ft.Text("确定要清空所有通话记录吗？此操作无法撤销。"),
                actions=[
                    ft.TextButton("取消", on_click=cancel_clear),
                    ft.TextButton("清空", on_click=confirm_clear, style=ft.ButtonStyle(color=ft.Colors.RED))
                ],
                actions_alignment=ft.MainAxisAlignment.END
            )
            
            self.page.overlay.append(confirm_dialog)
            confirm_dialog.open = True
            self.page.update()

        bs = ft.BottomSheet(
            ft.Container(
                ft.Column(
                    [
                        ft.ListTile(
                            leading=ft.Icon(ft.Icons.DELETE_SWEEP, color=ft.Colors.RED_400),
                            title=ft.Text("清空所有记录", color=ft.Colors.RED_400),
                            on_click=clear_logs_click
                        ),
                        ft.ListTile(
                            leading=ft.Icon(ft.Icons.CANCEL),
                            title=ft.Text("取消"),
                            on_click=lambda e: setattr(bs, 'open', False) or self.page.update()
                        ),
                    ],
                    tight=True,
                ),
                padding=10,
            ),
        )
        self.page.overlay.append(bs)
        bs.open = True
        self.page.update()
    
    def get_weekday(self, date_str):
        """根据日期字符串(MM.DD)返回星期几"""
        try:
            dt = datetime.strptime(f"{self.current_year}.{date_str}", "%Y.%m.%d")
            weekdays = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"]
            return weekdays[dt.weekday()]
        except:
            return "星期一"

    def create_call_item(self, log: dict):
        """创建通话记录项 - 图2样式"""
        # 格式化通话时长
        duration = log['call_duration']
        if duration < 60:
            duration_text = f"{duration}秒"
        else:
            minutes = duration // 60
            seconds = duration % 60
            duration_text = f"{minutes}分{seconds}秒" if seconds > 0 else f"{minutes}分钟"
        
        # 左侧日历小组件
        date_badge = ft.Container(
            content=ft.Stack([
                # 主体背景 (带边框)
                ft.Container(
                    content=ft.Column([
                        # 上半部分: 日期
                        ft.Container(
                            content=ft.Text(log['call_date'], size=13, color="#e53935", weight=ft.FontWeight.W_500),
                            alignment=ft.alignment.center,
                            expand=6, # 占比 70%
                            bgcolor="#fff7f7",
                            border_radius=ft.border_radius.only(top_left=4, top_right=4),
                            padding=ft.padding.only(top=3) # 往下移动
                        ),
                        # 分割线
                        ft.Container(height=1, bgcolor="#fbe0e9"),
                        # 下半部分: 星期
                        ft.Container(
                            content=ft.Text(log.get('weekday') if log.get('weekday') else self.get_weekday(log['call_date']), size=10, color="#888888"),
                            alignment=ft.alignment.center,
                            expand=4, # 占比 30%
                            bgcolor="#fefefe", 
                            border_radius=ft.border_radius.only(bottom_left=4, bottom_right=4)
                        )
                    ], spacing=0),
                    width=44,
                    height=40,
                    border=ft.border.all(1, "#fbe0e9"), # 框线颜色
                    border_radius=5,
                    padding=ft.padding.all(1), # 添加内边距防止遮挡边框
                    margin=ft.margin.only(top=4) # 留出耳朵位置
                ),
                # 两个耳朵 (加宽，线条不粗)
                ft.Container(
                    width=7, height=11, # 加宽
                    bgcolor="#fff7f7", 
                    border=ft.border.all(1.5, "#fbe0e9"), # 线条微粗但不如之前粗
                    border_radius=1, 
                    left=9, top=0
                ),
                ft.Container(
                    width=7, height=11, # 加宽
                    bgcolor="#fff7f7", 
                    border=ft.border.all(1.5, "#fbe0e9"), # 线条微粗但不如之前粗
                    border_radius=1,
                    left=28, top=0
                ),
            ], width=44, height=46),
            padding=ft.padding.only(right=10)
        )

        # 右侧详情内容
        details = ft.Column([
                # 第一行: 标题 + 电话号码
                ft.Container(
                    content=ft.Row([
                        ft.Row([
                            ft.Text("高清语音", size=15, weight=ft.FontWeight.BOLD, color="#333333"),
                            ft.Row([
                                create_phone_icon(size=16, color="#0bb415" if log['is_outgoing'] else "#5fa8f2", is_outgoing=log['is_outgoing']),
                                ft.Text("主叫" if log['is_outgoing'] else "被叫", size=10, weight=ft.FontWeight.W_500, color="#0bb415" if log['is_outgoing'] else "#5fa8f2")
                            ], spacing=2, vertical_alignment=ft.CrossAxisAlignment.CENTER)
                        ], spacing=8, vertical_alignment=ft.CrossAxisAlignment.CENTER),
                        ft.Container(expand=True),
                        ft.Text(log['phone_number'], size=16, weight=ft.FontWeight.W_600, color="#333333")
                    ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                    margin=ft.margin.only(bottom=5) # 增加底部间距
                ),
                
                # 第二行: 归属地标签 + 归属地值
                ft.Row([
                    ft.Text("对方号码归属地", size=13, color="#999999", weight=ft.FontWeight.W_500),
                    ft.Container(expand=True),
                    ft.Text(log['location'], size=13, color="#999999", weight=ft.FontWeight.W_500)
                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                
                # 接通时间
                ft.Row([
                    ft.Text("接通时间:", size=13, color="#999999", weight=ft.FontWeight.W_500),
                    ft.Container(expand=True),
                    ft.Text(log['connect_time'], size=13, color="#999999", weight=ft.FontWeight.W_500)
                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                
                # 通话时长
                ft.Row([
                    ft.Text("通话时长:", size=13, color="#999999", weight=ft.FontWeight.W_500),
                    ft.Container(expand=True),
                    ft.Text(duration_text, size=13, color="#999999", weight=ft.FontWeight.W_500)
                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                
                # 计费分钟数
                ft.Row([
                    ft.Text("计费分钟数:", size=13, color="#999999", weight=ft.FontWeight.W_500),
                    ft.Container(expand=True),
                    ft.Text(f"{log['billing_minutes']}分钟", size=13, color="#999999", weight=ft.FontWeight.W_500)
                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                
                # 通话费用
                ft.Row([
                    ft.Text("通话费用:", size=13, color="#999999", weight=ft.FontWeight.W_500),
                    ft.Container(expand=True),
                    ft.Text(f"¥{log['call_fee']:.2f}", size=13, color="#999999", weight=ft.FontWeight.W_500)
                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                
            ], spacing=5, expand=True)

        # 创建通话记录项容器(支持长按)
        item = ft.Container(
            content=ft.Row([
                date_badge,
                details
            ], vertical_alignment=ft.CrossAxisAlignment.START),
            padding=ft.padding.symmetric(horizontal=15, vertical=12),
            bgcolor=ft.Colors.WHITE,
            # border=ft.border.only(bottom=ft.BorderSide(0.5, "#f5f5f5")), # 移除旧边框
            on_long_press=self.on_call_log_long_press(log['id'])
        )
        
        # 包装容器和分割线
        return ft.Column([
            item,
            ft.Container(
                height=0.5, 
                bgcolor="#eeeeee", 
                margin=ft.margin.symmetric(horizontal=15) # 左右留空
            )
        ], spacing=0)
    
    def build_ui(self):
        """构建用户界面"""
        
        # 费用统计文本
        total_fee = self.db.get_total_fee()
        self.fee_text = ft.Text(f"{total_fee:.2f}元", size=20, weight=ft.FontWeight.BOLD, color="#fbfffd")
        
        # 头部区域 (包含顶部导航、费用统计、Tab栏)
        # 合并为一个容器以统一背景和消除间距
        header_content = ft.Column([
            # 1. 顶部导航栏内容 - 使用Stack实现标题绝对居中
            ft.Container(
                content=ft.Stack([
                    # 层1: 标题绝对居中
                    ft.Container(
                        content=ft.Column([
                            ft.Text(
                                "详单查询",
                                size=16,
                                color="#fbfffd",
                                weight=ft.FontWeight.NORMAL
                            ),
                            ft.Container(
                                content=ft.Text(
                                    self.top_phone_number, # 使用变量
                                    size=16,
                                    color="#fbfffd",
                                    ref=lambda c: setattr(self, 'top_phone_text', c) # 保存引用
                                ),
                                on_click=self.on_phone_number_click,
                                on_long_press=self.on_top_number_long_press # 添加长按事件
                            )
                        ], spacing=2, horizontal_alignment=ft.CrossAxisAlignment.CENTER),
                        alignment=ft.alignment.center,
                    ),
                    # 层2: 左右按钮
                    ft.Row([
                        # 左侧返回按钮
                        ft.Container(
                            content=create_arrow_canvas(size=22, color="#000000", stroke_width=2),
                            bgcolor="#ef625e",
                            border_radius=15,
                            width=30,
                            height=30,
                            alignment=ft.alignment.center,
                            margin=ft.margin.only(top=5) # 左侧保持大致居中
                        ),
                        # 右侧按钮组
                        ft.Container(
                            content=ft.Row([
                                ft.Container(
                                    content=create_star_canvas(size=24, color="#000000", stroke_width=2),
                                    bgcolor="#e8b5b0",
                                    border_radius=15,
                                    width=30,
                                    height=30,
                                    alignment=ft.alignment.center
                                ),
                                # 合并后的按钮组: 三个点 | 历史记录
                                ft.Container(
                                    content=ft.Row([
                                        # 三个点按钮
                                        ft.Container(
                                            content=ft.Row([
                                                ft.Container(width=4, height=4, bgcolor="#000000", border_radius=2),
                                                ft.Container(width=6, height=6, bgcolor="#000000", border_radius=3),
                                                ft.Container(width=4, height=4, bgcolor="#000000", border_radius=2)
                                            ], spacing=3, alignment=ft.MainAxisAlignment.CENTER),
                                            width=30,
                                            height=30,
                                            alignment=ft.alignment.center,
                                            on_click=lambda e: self.show_more_menu() # 添加点击事件
                                        ),
                                        # 分隔线
                                        ft.Container(
                                            width=1,
                                            height=16,
                                            bgcolor=ft.Colors.with_opacity(0.5, "#ffffff")
                                        ),
                                        # 历史记录按钮
                                        ft.Container(
                                            content=ft.Stack([
                                                ft.Container(width=16, height=16, border=ft.border.all(1.8, "#000000"), border_radius=8),
                                                ft.Container(width=5, height=5, bgcolor="#000000", border_radius=2.5)
                                            ], alignment=ft.alignment.center),
                                            width=30,
                                            height=30,
                                            alignment=ft.alignment.center
                                        )
                                    ], spacing=2, alignment=ft.MainAxisAlignment.CENTER),
                                    bgcolor="#e8b5b0",
                                    border_radius=15,
                                    padding=ft.padding.symmetric(horizontal=5),
                                    height=30,
                                    alignment=ft.alignment.center
                                )
                            ], spacing=10),
                            margin=ft.margin.only(top=17) # 右侧大幅下移，对齐第二行电话号码
                        )
                    ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN, vertical_alignment=ft.CrossAxisAlignment.START)
                ], alignment=ft.alignment.center),
                padding=ft.padding.only(left=10, right=10, top=40, bottom=10)
            ),
            
            # 2. 费用统计内容
            ft.Container(
                content=ft.Row([
                    ft.Text("通话费用总计", size=20, weight=ft.FontWeight.BOLD, color="#fbfffd"),
                    ft.Container(width=3), # 增加间距
                    self.fee_text,
                    ft.Container(expand=True),
                    ft.Container(
                        content=ft.Text("查账单", size=12, color="#fffbeb"),
                        border=ft.border.all(0.8, "#fffbeb"),  # 边框调细
                        padding=ft.padding.symmetric(horizontal=15, vertical=6),
                        border_radius=15
                    )
                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN, vertical_alignment=ft.CrossAxisAlignment.CENTER),
                padding=ft.padding.symmetric(horizontal=20, vertical=10) # 减小上下间距
            ),
            
            # 3. Tab标签栏内容
            ft.Container(
                content=ft.Row([
                    ft.Container(
                        content=ft.Column([
                            ft.Text("通话", size=15, weight=ft.FontWeight.BOLD, color="#fbfffd"),
                            ft.Container(height=2, width=25, bgcolor="#fbfffd", border_radius=2)
                        ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=5),
                        padding=10
                    ),
                    # 其他Tab也使用Column结构和透明占位符，确保对齐
                    ft.Container(
                        content=ft.Column([
                            ft.Text("流量", size=15, color="#fbfffd"),
                            ft.Container(height=2, width=30, bgcolor=ft.Colors.TRANSPARENT)
                        ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=5),
                        padding=10
                    ),
                    ft.Container(
                        content=ft.Column([
                            ft.Text("短彩信", size=15, color="#fbfffd"),
                            ft.Container(height=2, width=30, bgcolor=ft.Colors.TRANSPARENT)
                        ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=5),
                        padding=10
                    ),
                    ft.Container(
                        content=ft.Column([
                            ft.Text("增值业务", size=15, color="#fbfffd"),
                            ft.Container(height=2, width=30, bgcolor=ft.Colors.TRANSPARENT)
                        ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=5),
                        padding=10
                    )
                ], alignment=ft.MainAxisAlignment.SPACE_AROUND, vertical_alignment=ft.CrossAxisAlignment.CENTER),
                padding=ft.padding.only(bottom=10)
            )
        ], spacing=0) # 消除行间距

        # 头部整体容器
        header_section = ft.Container(
            content=ft.Stack([
                # 指纹纹路装饰层 - 放在底层，覆盖整个头部
                # 往右上移动: 使用 right 和 top 属性进行定位
                ft.Container(
                    content=create_fingerprint_pattern(width=350, height=200),
                    right=-80,  # 往右移出边界更多
                    top=-50,    # 往上移出边界更多
                ),
                # 内容层
                header_content
            ]),
            gradient=ft.LinearGradient(
                begin=ft.alignment.center_left,
                end=ft.alignment.center_right,
                colors=["#eb4c46", "#ee675f"]
            )
        )
        
        # 月份选择器
        months = ["12月", "11月", "10月", "9月", "8月", "7月", "6月"]
        
        # 内部方块大小 (固定以保持正方形，外层自适应)
        inner_box_size = 48 # 调大一点，减少间距
        top_section_height = 26 # 再次微调高度，留出边框
        bottom_section_height = 15 # 再次微调高度
        
        selector_controls = []
        
        # 添加月份按钮
        for month in months:
            is_selected = month == self.current_month
            
            # 统一使用上下分层结构，确保对齐
            content = ft.Column([
                ft.Container(
                    content=ft.Text(
                        month,
                        size=15,
                        color="#e94947" if is_selected else "#333333",
                        # font_family="Arial", # 移除，使用全局字体(微软雅黑)
                        style=ft.TextStyle(letter_spacing=-1.0)
                    ),
                    bgcolor="#fff5f5" if is_selected else None,
                    alignment=ft.alignment.center,
                    height=top_section_height, # 固定高度
                    width=inner_box_size,
                    # 上半部分圆角 (仅选中时)
                    border_radius=ft.border_radius.only(top_left=5, top_right=5) if is_selected else None
                ),
                ft.Container(
                    content=ft.Text(
                        self.current_year,
                        size=11, # 调小字号
                        color="#e94947" if is_selected else "#333333", # 统一未选中颜色为深色
                        # font_family="SimHei", # 移除，使用全局字体(微软雅黑)
                        style=ft.TextStyle(letter_spacing=0)  # 恢复正常字距
                    ),
                    bgcolor="#fcfcf5" if is_selected else None,
                    alignment=ft.alignment.center,
                    height=bottom_section_height, # 固定高度
                    width=inner_box_size,
                    # 下半部分圆角 (仅选中时)
                    border_radius=ft.border_radius.only(bottom_left=5, bottom_right=5) if is_selected else None
                )
            ], spacing=0)
            
            inner = ft.Container(
                content=content,
                width=inner_box_size,
                height=inner_box_size,
                border=ft.border.all(1, "#eb4c46") if is_selected else ft.border.all(1, ft.Colors.TRANSPARENT),
                border_radius=6,
                alignment=ft.alignment.center
            )
            
            # 外层自适应容器
            selector_controls.append(
                ft.Container(
                    content=inner,
                    expand=1,
                    alignment=ft.alignment.center
                )
            )
            
        # # 添加间隔 (月份与日历之间的间隔稍大)
        # selector_controls.append(ft.Container(width=15)) # 加大间隔
        
        # 添加日历按钮
        # 为了实现“按日选择”与“2025”底部水平一致，采用相同的布局结构
        calendar_inner = ft.Container(
            content=ft.Column([
                # 上半部分：放图标
                ft.Container(
                    content=create_calendar_icon(size=25, color="#e57d80", bg_color="#ffdee3"), # 再次调大图标
                    alignment=ft.alignment.center,
                    height=top_section_height,
                    width=60, # 加宽以容纳文字
                ),
                # 下半部分：放文字
                ft.Container(
                    content=ft.Text("按日选择", size=10, color="#e57d80"), # 字体微调为10以防溢出
                    alignment=ft.alignment.center,
                    height=bottom_section_height,
                    width=60
                )
            ], spacing=0),
            width=64, # 加宽容器
            height=inner_box_size,
            alignment=ft.alignment.center
        )
        
        selector_controls.append(
            ft.Container(
                content=calendar_inner,
                expand=1, # 保持自适应，但内容容器较宽
                alignment=ft.alignment.center
            )
        )

        # 设置页面背景色为红色(配合顶部渐变)，使圆角效果自然
        self.page.bgcolor = "#ee675f"

        # 月份选择器 - 去除背景
        month_selector = ft.Container(
            content=ft.Row(
                controls=selector_controls,
                spacing=0,  # 外层无间距，由expand自动分配
                alignment=ft.MainAxisAlignment.CENTER,
                vertical_alignment=ft.CrossAxisAlignment.END
            ),
            padding=ft.padding.only(left=10, right=10, top=10, bottom=5)
        )
        
        # 筛选器栏 - 仿照图2重构
        filter_bar = ft.Container(
            content=ft.Row([
                # 1. 顺序 (带上下箭头)
                ft.Container(
                    content=ft.Row([
                        ft.Text("顺序", size=12, color="#3f3f3f"), 
                        ft.Container(
                            content=create_sort_icons(size=16, color_up="#a3a3a3", color_down="#353535"), # 颜色互换：上浅下深
                            alignment=ft.alignment.center
                        )
                    ], spacing=2),
                    on_click=lambda e: print("顺序 clicked")
                ),
                
                # 2. 呼叫类型 (灰色下拉箭头)
                ft.Container(
                    content=ft.Row([
                        ft.Text("呼叫类型", size=12, color=ft.Colors.GREY_600), # 字体缩小到12
                        ft.Container(width=2), # 微小间距
                        create_dropdown_icon(size=8, color=ft.Colors.GREY_400) # 使用自定义下拉图标，等边三角形
                    ], spacing=0, vertical_alignment=ft.CrossAxisAlignment.CENTER), 
                    on_click=lambda e: print("呼叫类型 clicked")
                ),
                
                # 3. 费用 (灰色下拉箭头)
                ft.Container(
                    content=ft.Row([
                        ft.Text("费用", size=12, color=ft.Colors.GREY_600), # 字体缩小到12
                        ft.Container(width=2), # 微小间距
                        create_dropdown_icon(size=8, color=ft.Colors.GREY_400) # 使用自定义下拉图标
                    ], spacing=0, vertical_alignment=ft.CrossAxisAlignment.CENTER), 
                    on_click=lambda e: print("费用 clicked")
                ),
                
                # 4. 号码筛选 (胶囊搜索框)
                ft.Container(
                    content=ft.Row([
                        ft.Text("号码筛选", size=14, color="#c8c8c8"), # 字号调大到14
                        ft.Row([
                            ft.Text("|", size=14, color="#e0e0e0"), 
                            create_search_icon(size=16, color="#939393", stroke_width=1.8), 
                        ], spacing=5, vertical_alignment=ft.CrossAxisAlignment.CENTER)
                    ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN, vertical_alignment=ft.CrossAxisAlignment.CENTER), 
                    bgcolor="#f7f7f7", 
                    padding=ft.padding.symmetric(horizontal=10, vertical=3), # 垂直padding微增，水平padding微减
                    border_radius=15,
                    width=120, # 宽度缩短
                    on_click=lambda e: print("号码筛选 clicked")
                )
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            padding=ft.padding.symmetric(horizontal=15, vertical=10),
            border=ft.border.only(bottom=ft.BorderSide(1, "#f0f0f0")) # 边框颜色更浅
        )
        
        # 通话记录列表
        logs = self.db.get_all_logs()
        self.call_list = ft.Column([], spacing=0)
        
        for log in logs:
            self.call_list.controls.append(self.create_call_item(log))
        
        # 添加底部提示："没有更多了"
        if logs:  # 只有当有记录时才显示
            self.call_list.controls.append(
                ft.Column([
                    # 分割线
                    ft.Container(
                        height=0.5,
                        bgcolor="#eeeeee",
                        margin=ft.margin.symmetric(horizontal=15)
                    ),
                    # "没有更多了"文字
                    ft.Container(
                        content=ft.Text(
                            "没有更多了",
                            size=13,
                            color="#999999",
                            weight=ft.FontWeight.W_500
                        ),
                        alignment=ft.alignment.center,
                        padding=ft.padding.symmetric(vertical=15)
                    )
                ], spacing=0)
            )
        
        # 列表容器 - 去除背景，直接作为Column的一部分
        call_list_column = ft.Column([
                self.call_list
            ], scroll=ft.ScrollMode.HIDDEN, expand=True)
        
        # 底部功能栏
        bottom_bar = ft.Container(
            content=ft.Row([
                ft.Text("温馨提示", size=12, color=ft.Colors.GREY_600),
                ft.Text("|", size=12, color=ft.Colors.GREY_400),
                ft.Text("安全验证", size=12, color=ft.Colors.GREY_600),
                ft.Text("|", size=12, color=ft.Colors.GREY_400),
                ft.Text("满意度调查", size=12, color=ft.Colors.GREY_600),
                ft.Text("|", size=12, color=ft.Colors.GREY_400),
                ft.Text("下载详单", size=12, color=ft.Colors.GREY_600)
            ], alignment=ft.MainAxisAlignment.CENTER),
            height=60, # 加高
            alignment=ft.alignment.top_center, # 内容靠上
            padding=ft.padding.only(top=10), # 顶部间距
            bgcolor="#f9f9f9",
            shadow=ft.BoxShadow(
                spread_radius=1,
                blur_radius=5,
                color=ft.Colors.with_opacity(0.08, ft.Colors.BLACK),
                offset=ft.Offset(0, -2)
            )
        )
        
        # 下半部分统一的白色圆角容器
        content_container = ft.Container(
            content=ft.Column([
                month_selector,
                filter_bar,
                call_list_column, # 移除 show_name_toggle
                bottom_bar
            ], spacing=0, expand=True),
            bgcolor=ft.Colors.WHITE,
            border_radius=ft.border_radius.only(top_left=20, top_right=20),
            expand=True
        )
        
        # 组装整个页面
        self.page.add(
            ft.Column([
                header_section,
                content_container
            ], spacing=0, expand=True)
        )


def main(page: ft.Page):
    """主函数 - 带启动屏"""
    # 隐藏标题栏和窗口控件
    page.title = "中国联通"
    page.padding = 0
    
    # 设置启动屏背景色
    page.bgcolor = "#fef5f5"
    
    # 设置启动屏状态栏样式 (浅色背景，深色图标)
    page.system_overlay_style = ft.SystemOverlayStyle(
        status_bar_color=ft.Colors.TRANSPARENT,
        status_bar_icon_brightness=ft.Brightness.DARK,
        system_navigation_bar_color="#fef5f5",
        system_navigation_bar_icon_brightness=ft.Brightness.DARK,
        system_navigation_bar_divider_color=ft.Colors.TRANSPARENT
    )
    
    # 创建启动屏 - 自适应屏幕
    splash_screen = ft.Container(
        content=ft.Image(
            src="assets/splash.png",
            fit=ft.ImageFit.CONTAIN,  # 保持图片比例，完整显示
        ),
        bgcolor="#fef5f5",
        expand=True,
        alignment=ft.alignment.center  # 图片居中显示
    )
    
    # 显示启动屏
    page.add(splash_screen)
    page.update()
    
    # 等待1.5秒
    time.sleep(1.5)
    
    # 清除启动屏，加载主应用
    page.controls.clear()
    CallLogApp(page)


if __name__ == "__main__":
    ft.app(target=main)

