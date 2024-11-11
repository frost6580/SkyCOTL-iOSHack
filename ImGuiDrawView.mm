#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include "ImGui/imgui.h"
#include "ImGui/imgui_impl_metal.h"

#include <string>
#include <vector>
#include <cmath>

#include "FloatButton.h"
#include "Sky.h"

#include "JsonData/Candles.h"
#include "JsonData/EdenStatues.h"
#include "JsonData/Map.h"
#include "JsonData/WingBuffs.h"

#include "nlohmann/json.hpp"

@interface ImGuiDrawView : UIViewController

+ (void)showChange:(BOOL)open;

@end

@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, readonly) MTKView *mtkView;
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@end

@implementation ImGuiDrawView

Sky Sky;
Memory m;

using json = nlohmann::json;

nlohmann::json JSON_CANDLES = nlohmann::json::parse(Candles_json);
nlohmann::json JSON_EDENSTATUES = nlohmann::json::parse(EdenStatues_json);
nlohmann::json JSON_MAP = nlohmann::json::parse(Map_json);
nlohmann::json JSON_WINGBUFFS = nlohmann::json::parse(WingBuffs_json);

std::vector<DrawObjectData> drawObjectsData;

static bool IMGUI_ACTIVE = false;

static ImGuiDrawView *IMGUIVIEW = nil;

+ (void)load {
    [super load];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        IMGUIVIEW = [[ImGuiDrawView alloc] init];
        UIWindow *mainWindow = [UIApplication sharedApplication].windows.firstObject;
        if (mainWindow && mainWindow.rootViewController) {
            [mainWindow.rootViewController.view addSubview:IMGUIVIEW.view];

            FloatButton *floatButton = [[FloatButton alloc] initWithFrame:CGRectMake(100, 100, 50, 50) 
                icon:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Love" ofType:@"png" inDirectory:@"PlugIns/Sky: Children of the Light.appex/Sticker Pack.stickerpack"]] 
                action:^{
                    IMGUI_ACTIVE = !IMGUI_ACTIVE;
                    [ImGuiDrawView showChange:IMGUI_ACTIVE];
                }];
            [mainWindow addSubview:floatButton];

        }
    });
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device)
    {
        NSLog(@"Metal is not supported");
        abort();
    }

    // Setup Dear ImGui context
    // FIXME: This example doesn't have proper cleanup...
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

    // Setup Dear ImGui style
    ImGui::StyleColorsDark();
    //ImGui::StyleColorsLight();

    //ImGuiStyle& style = ImGui::GetStyle();
    //style.Colors[ImGuiCol_Text] = ImVec4(1.0f, 0.0f, 0.0f, 1.0f);

    io.Fonts->AddFontFromFileTTF("/System/Library/Fonts/LanguageSupport/PingFang.ttc", 20.f, NULL, io.Fonts->GetGlyphRangesChineseFull());

    // Setup Renderer backend
    ImGui_ImplMetal_Init(_device);

    return self;
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

- (void)loadView
{
    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mtkView.device = self.device;
    self.mtkView.delegate = self;

    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor clearColor];
    self.mtkView.clipsToBounds = YES;
}

- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor == nil)
    {
        [commandBuffer commit];
		return;
    }

    [self.view setUserInteractionEnabled: IMGUI_ACTIVE];

    static bool IS_GLOBAL_SPEED = true;
    static bool IS_LOCAL_SPEED = true;
    static bool IS_INF_WING = false;
    static bool IS_ALWAYS_CANDLE = false;
    static bool IS_INF_FIREWORK = true;
    static bool IS_GLOW = false;
    static bool IS_NOCAPE = false;
    static bool IS_AUTO_BURN_FLOWER = false;
    static bool IS_AUTO_BURN_CANDLE = false;
    static bool IS_AUTO_COLLECT_WAX = false;
    static bool IS_HIDDEN_CLOUD = false;
    static bool IS_HIDDEN_FOG = false;
    static bool IS_HIDDEN_WATER = false;
    static bool IS_HIDDEN_GRASS = false;
    static bool IS_DISABLE_GRAVITY = false;
    static bool IS_DISABLE_MULTIPLAY = false;

    static float GLOBAL_SPEED_VALUE = 1.f;
    static float LOCAL_SPEED_VALUE = 1.f;
    static float TEREPORT_RATIO_VALUE = 1.f;
    static float AUTO_CR_SPEED_VALUE = 1.f;

    static const char* WING_COUNT_LIST[] = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14"};
    static const char* OPEN_CLOSET_LIST[] = {"服", "ケープ", "髪", "仮面", "装飾"};
    static const char* MAGIC_LIST[] = {"なし"};
    static const char* CANDLE_COUNT_LIST[] = {"キャンドル", "ハート", "シーズンキャンドル", "星のキャンドル", "シーズンパス", "イベントチケット"};
    static const char* MAP_LIST[] = {"なし"};
    static const char* WING_LIGHT_LIST[] = {"なし"};

    static int WING_COUNT_INDEX = 11;
    static int OPEN_CLOSET_INDEX = 0;
    static int MAGIC_INDEX = 0;
    static int CANDLE_COUNT_INDEX = 0;
    static int MAP_INDEX = 0;
    static int WING_LIGHT_INDEX = 0;


    // Start the Dear ImGui frame
    ImGui_ImplMetal_NewFrame(renderPassDescriptor);
    ImGui::NewFrame();

    if(IMGUI_ACTIVE){
        ImGui::SetNextWindowPos(ImVec2(io.DisplaySize.x - 400, 0), ImGuiCond_FirstUseEver);
        ImGui::SetNextWindowSize(ImVec2(400, 260),ImGuiCond_FirstUseEver);
        ImGui::Begin("FMOD", nullptr, ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove);
        
        if (ImGui::BeginTabBar("タブ", ImGuiTabBarFlags_FittingPolicyResizeDown)) {
            if (ImGui::BeginTabItem("基本機能")) {

                if(ImGui::Checkbox("##全体加速", &IS_GLOBAL_SPEED)) Sky.SetGlobalSpeed(1.f);
                ImGui::SameLine();
                ImGui::SliderFloat("全体加速", &GLOBAL_SPEED_VALUE, 1.0f, 10.0f, "%.3f");
                
                if(ImGui::Checkbox("##単体加速", &IS_LOCAL_SPEED)) Sky.SetLocalSpeed(1.f);
                ImGui::SameLine();
                ImGui::SliderFloat("単体加速", &LOCAL_SPEED_VALUE, 1.0f, 9.79f, "%.3f");
                if(IS_LOCAL_SPEED) Sky.SetLocalSpeed(LOCAL_SPEED_VALUE);

                if(ImGui::Checkbox("無限飛行", &IS_INF_WING)) Sky.SetInfWing(IS_INF_WING);

                if(ImGui::Checkbox("常に灯す", &IS_ALWAYS_CANDLE)) Sky.SetAlwaysCandle(IS_ALWAYS_CANDLE);

                if(ImGui::Checkbox("無限花火", &IS_INF_FIREWORK)) Sky.SetInfFirework(IS_INF_FIREWORK);
                if(IS_INF_FIREWORK) Sky.SetInfFirework(IS_INF_FIREWORK);

                ImGui::EndTabItem();
            }
            
            if (ImGui::BeginTabItem("プレイヤー")) {
                ImGui::SetNextItemWidth(200.f);
                ImGui::Combo("##羽の枚数リスト", &WING_COUNT_INDEX, WING_COUNT_LIST, IM_ARRAYSIZE(WING_COUNT_LIST));
                ImGui::SameLine();
                if (ImGui::Button("変更##羽の枚数")) {
                    uint32_t count;
                    switch (WING_COUNT_INDEX) {
                        case 0: count = 1; break;
                        case 1: count = 2; break;
                        case 2: count = 5; break;
                        case 3: count = 10; break;
                        case 4: count = 20; break;
                        case 5: count = 35; break;
                        case 6: count = 55; break;
                        case 7: count = 75; break;
                        case 8: count = 100; break;
                        case 9: count = 120; break;
                        case 10: count = 150; break;
                        case 11: count = 200; break;
                        case 12: count = 250; break;
                        case 13: count = 300; break;
                    }
                    Sky.SetWingCount(count);
                }
                ImGui::SameLine();
                ImGui::Text("羽の枚数");

                ImGui::SetNextItemWidth(200.f);
                ImGui::Combo("##クローゼットリスト", &OPEN_CLOSET_INDEX, OPEN_CLOSET_LIST, IM_ARRAYSIZE(OPEN_CLOSET_LIST));
                ImGui::SameLine();
                if (ImGui::Button("開く##クローゼット")) {
                    uint32_t index;
                    switch (OPEN_CLOSET_INDEX) {
                        case 0: index = 0; break;
                        case 1: index = 1; break;
                        case 2: index = 2; break;
                        case 3: index = 3; break;
                        case 4: index = 8; break;
                    }
                    Sky.SetOpenCloset(index);
                }
                ImGui::SameLine();
                ImGui::Text("クローゼット");

                ImGui::SetNextItemWidth(200.0f);
                ImGui::Combo("##魔法リスト", &MAGIC_INDEX, MAGIC_LIST, IM_ARRAYSIZE(MAGIC_LIST));
                ImGui::SameLine();
                if (ImGui::Button("付与##魔法リスト")) {
                    uint32_t index;
                    switch (MAGIC_INDEX) {
                        case 0: index = 0; break;
                    }
                }
                ImGui::SameLine();
                ImGui::Text("魔法");

                ImGui::SetNextItemWidth(200.0f);
                ImGui::Combo("##アイテムの個数リスト", &CANDLE_COUNT_INDEX, CANDLE_COUNT_LIST, IM_ARRAYSIZE(CANDLE_COUNT_LIST));
                ImGui::SameLine();
                if (ImGui::Button("変更##アイテムの個数リスト")) {
                    uint32_t index;
                    switch (CANDLE_COUNT_INDEX) {
                        case 0: index = 0; break;
                    }
                }
                ImGui::SameLine();
                ImGui::Text("アイテムの個数");

                if(ImGui::Checkbox("発光", &IS_GLOW)) Sky.SetGlow(1.f);

                if(ImGui::Checkbox("ケープ無し", &IS_NOCAPE)) Sky.SetNoCape(IS_NOCAPE);

                ImGui::EndTabItem();
            }

            if (ImGui::BeginTabItem("移動系")) {

                ImGui::Text("移動");
                ImGui::SameLine();
                if(ImGui::Button("上")) Sky.InputTeleport(0, TEREPORT_RATIO_VALUE);
                ImGui::SameLine();
                if(ImGui::Button("下")) Sky.InputTeleport(1, TEREPORT_RATIO_VALUE);
                ImGui::SameLine();
                if(ImGui::Button("前方")) Sky.InputTeleport(2,TEREPORT_RATIO_VALUE);
                ImGui::SameLine();
                ImGui::SetNextItemWidth(140.0f);
                ImGui::SliderFloat("倍率", &TEREPORT_RATIO_VALUE, 1.0f, 30.0f, "%.3f");

                ImGui::Text("自動キャンマラ");
                ImGui::SameLine();
                ImGui::Button("実行");
                ImGui::SameLine();
                ImGui::SetNextItemWidth(140.0f);
                ImGui::SliderFloat("速さ", &AUTO_CR_SPEED_VALUE, 1.0f, 3.0f, "%.3f");

                ImGui::SetNextItemWidth(200.0f);
                ImGui::Combo("##マップリスト", &MAP_INDEX, MAP_LIST, IM_ARRAYSIZE(MAP_LIST));
                ImGui::SameLine();
                if (ImGui::Button("移動##マップリスト")) {
                    uint32_t index;
                    switch (MAP_INDEX) {
                        case 0: index = 0; break;
                    }
                }
                ImGui::SameLine();
                ImGui::Text("マップ");

                ImGui::SetNextItemWidth(200.0f);
                ImGui::Combo("##光の子リスト", &WING_LIGHT_INDEX, WING_LIGHT_LIST, IM_ARRAYSIZE(WING_LIGHT_LIST));
                ImGui::SameLine();
                if (ImGui::Button("移動##光の子リスト")) {
                    uint32_t index;
                    switch (WING_LIGHT_INDEX) {
                        case 0: index = 0; break;
                    }
                }
                ImGui::SameLine();
                ImGui::Text("光の子");

                ImGui::EndTabItem();
            }

            if (ImGui::BeginTabItem("その他")) {
                
                ImGui::Checkbox("自動化##闇の花を燃やす", &IS_AUTO_BURN_FLOWER);
                ImGui::SameLine();
                if(ImGui::Button("実行##闇の花を燃やす")) Sky.SetBurnFlowers();
                ImGui::SameLine();
                ImGui::Text("闇の花を燃やす");

                ImGui::Checkbox("自動化##キャンドルを燃やす", &IS_AUTO_BURN_CANDLE);
                ImGui::SameLine();
                if(ImGui::Button("実行##キャンドルを燃やす")) Sky.SetBurnCandles();
                ImGui::SameLine();
                ImGui::Text("キャンドルを燃やす");
                
                ImGui::Checkbox("自動化##火種回収", &IS_AUTO_COLLECT_WAX);
                ImGui::SameLine();
                ImGui::Button("実行##火種回収");
                ImGui::SameLine();
                ImGui::Text("火種回収");

                if(ImGui::Checkbox("雲非表示", &IS_HIDDEN_CLOUD)) Sky.SetHiddenCloud(IS_HIDDEN_CLOUD);

                if(ImGui::Checkbox("霧非表示", &IS_HIDDEN_FOG)) Sky.SetHiddenFog(IS_HIDDEN_FOG);

                if(ImGui::Checkbox("水面非表示", &IS_HIDDEN_WATER)) Sky.SetHiddenWater(IS_HIDDEN_WATER);

                if(ImGui::Checkbox("草非表示", &IS_HIDDEN_GRASS)) Sky.SetHiddenGrass(IS_HIDDEN_GRASS);

                if(ImGui::Checkbox("無重力", &IS_DISABLE_GRAVITY)) Sky.SetDisableGravity(IS_DISABLE_GRAVITY);

                if(ImGui::Checkbox("オフラインモード", &IS_DISABLE_MULTIPLAY)) Sky.SetDisableOnline(IS_DISABLE_MULTIPLAY);

                ImGui::EndTabItem();
            }

            if (ImGui::BeginTabItem("開発者用")) {
                ImGui::Text("マップ名: %s", Sky.GetMapString().c_str());
                ImGui::Text("マップID: %u", Sky.GetMapID());
                Vec3 Pos = Sky.GetLocalPlayerPos();
                ImGui::Text("座標: X: %.3f, Y: %.3f, Z: %.3f", Pos.x, Pos.y, Pos.z);
                Vec3 Angle = Sky.GetLocalPlayerAngle();
                Angle.x *= (180.0f / M_PI);
                Angle.y *= (180.0f / M_PI);
                Angle.z *= (180.0f / M_PI);
                ImGui::Text("角度: X: %.3f, Y: %.3f, Z: %.3f", Angle.x, Angle.y, Angle.z);
                Vec3 ViewAngle = Sky.GetViewAngle();
                ViewAngle.x *= (180.0f / M_PI);
                ViewAngle.y *= (180.0f / M_PI);
                ViewAngle.z *= (180.0f / M_PI);
                ImGui::Text("視野: X: %.3f, Y: %.3f, Z: %.3f", ViewAngle.x, ViewAngle.y, ViewAngle.z);
                Vec2 Height = Sky.GetLocalPlayerHeight();
                ImGui::Text("身長: Height: %.4f, Scale: %.4f", Height.x, Height.y);

                if(ImGui::Button("テスト##01")){
                    Sky.SetBurnFlowers(false);
                };
                
                //ImGui::Text("ベースアドレス: %p", (void*)Sky.Addr.BaseAddr);
                ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / io.Framerate, io.Framerate);
                ImGui::EndTabItem();
            }

            ImGui::EndTabBar();
        }
        
        ImGui::End();
    }

    if(IS_GLOBAL_SPEED) Sky.SetGlobalSpeed(GLOBAL_SPEED_VALUE);
    if(IS_ALWAYS_CANDLE) Sky.SetAlwaysCandle(IS_ALWAYS_CANDLE);
    if(IS_GLOW) Sky.SetGlow(999.f);
    if(IS_NOCAPE) Sky.SetNoCape(IS_NOCAPE);
    if(IS_AUTO_BURN_FLOWER) Sky.SetBurnFlowers(IS_AUTO_BURN_FLOWER);
    if(IS_AUTO_BURN_CANDLE) Sky.SetBurnCandles(IS_AUTO_BURN_CANDLE);

    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::SetNextWindowSize(ImVec2(ImGui::GetIO().DisplaySize.x, ImGui::GetIO().DisplaySize.y)); 
    ImGui::Begin("##ESP", nullptr, ImGuiWindowFlags_NoDecoration | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoBackground | ImGuiWindowFlags_NoInputs);

    if(Sky.IsChangeCurrentMapName()){
        drawObjectsData.clear();

        std::string CurrentMapName = Sky.GetMapString();

        for (const auto& buff : JSON_WINGBUFFS) {
            std::string map = buff["map"];
            if(CurrentMapName != map) continue;
            std::string name = buff["name"];
            Vec3 pos = {buff["x"], buff["y"], buff["z"]};
            
            drawObjectsData.push_back({name, pos});
        }

    }

    ImDrawList* draw_list = ImGui::GetWindowDrawList();
    ImU32 color = IM_COL32(255, 255, 0, 255);
    ViewMatrix viewMatrix = Sky.GetViewMatrix();
    uint32_t screenWidth = static_cast<uint32_t>(ImGui::GetIO().DisplaySize.x);
    uint32_t screenHeight = static_cast<uint32_t>(ImGui::GetIO().DisplaySize.y);

    ImVec2 p1(screenWidth / 2, 0);

    for (const auto& drawObject : drawObjectsData) {

        Vec2 screenPos;

        if (m.WorldToScreen(drawObject.Pos, screenPos, viewMatrix.Matrix, screenWidth, screenHeight)) {
            
            ImVec2 p2(screenPos.x, screenPos.y);
            draw_list->AddLine(p1, p2, color);

            ImVec2 textSize = ImGui::CalcTextSize(drawObject.Context.c_str());
            ImVec2 textPos = ImVec2(screenPos.x - textSize.x / 2, screenPos.y - textSize.y / 2);
            draw_list->AddText(textPos, color, drawObject.Context.c_str());
        }

    }

    ImGui::End();

    // Rendering
    ImGui::Render();
    ImDrawData* draw_data = ImGui::GetDrawData();
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder pushDebugGroup:@"Dear ImGui rendering"];
    ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
    [renderEncoder popDebugGroup];
    [renderEncoder endEncoding];

	// Present
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

-(void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
}

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event      { [self updateIOWithTouchEvent:event]; }
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event      { [self updateIOWithTouchEvent:event]; }
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event  { [self updateIOWithTouchEvent:event]; }
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event      { [self updateIOWithTouchEvent:event]; }

+ (void)showChange:(BOOL)open
{
    IMGUI_ACTIVE = open;
}

@end
