#include "Memory.h"

#include <cmath>

struct DrawObjectData {
    std::string Context;
    Vec3 Pos;
};

class Sky
{
private:
    Memory m;
    struct {
        const std::vector<uintptr_t> CollectEdenCandle = {0x19B2188};
        const std::vector<uintptr_t> CollectWingLight = {0x1A63D20};
        const std::vector<uintptr_t> HiddenClouds = {0x1BA186C - 0x4};
        const std::vector<uintptr_t> InfFly = {0x1BA186C};
        const std::vector<uintptr_t> HiddenGrass = {0x1BB74C0};
        const std::vector<uintptr_t> DisableOnline = {0x1BCBA38};
        const std::vector<uintptr_t> HiddenWater = {0x1BD111C};
        const std::vector<uintptr_t> DisableGravity = {0x1BEDFBC};
        const std::vector<uintptr_t> WalkingSpeed = {0x1BEDFF0};
        const std::vector<uintptr_t> DivingSpeed = {0x1BEE4E4};
        const std::vector<uintptr_t> SwimmingSpeed = {0x1BEE4E4 + 0x8};
        const std::vector<uintptr_t> HiddenFog = {0x1C9834C};
        const std::vector<uintptr_t> ViewMatrix = {0x1d92430, 0x58, 0x370};
        const std::vector<uintptr_t> MapString = {0x1d92430, 0x58, 0x478};
        const std::vector<uintptr_t> WingCount = {0x1d92430, 0x8, 0x648, 0x6180};
        const std::vector<uintptr_t> LocalPlayerPos = {0x1d92430, 0x10, 0x38, 0x0};
        const std::vector<uintptr_t> LocalPlayerAngle = {0x1d92430, 0x10, 0x38, 0x20};
        const std::vector<uintptr_t> CurrentMapID = {0x1d92430, 0x10, 0x38, 0x5458};
        const std::vector<uintptr_t> Glow = {0x1d92430, 0x10, 0x68, 0x4bc};
        const std::vector<uintptr_t> Costume = {0x1d92430, 0x10, 0x78, 0x44};
        const std::vector<uintptr_t> LocalPlayerHeight = {0x1d92430, 0x10, 0x78, 0x177c};
        const std::vector<uintptr_t> Shout = {0x1d92430, 0x10, 0x78, 0x1870};
        const std::vector<uintptr_t> InfFirework = {0x1d92430, 0x10, 0x78, 0x1884};
        const std::vector<uintptr_t> CandleCount = {0x1d92430, 0x10, 0xa0, 0x78};
        const std::vector<uintptr_t> NoCape = {0x1d92430, 0x10, 0xa0, 0xb204};
        const std::vector<uintptr_t> Magic = {0x1d92430, 0x10, 0xb8, 0x10};
        const std::vector<uintptr_t> OpenCloset = {0x1d92430, 0x50, 0x120, 0x54};
        const std::vector<uintptr_t> GlobalSpeed = {0x1d92430, 0x30, 0x28};
        const std::vector<uintptr_t> ViewAngle = {0x1d92430, 0x60, 0x50, 0x59c};
        const std::vector<uintptr_t> CandleList = {0x1d92430, 0x18, 0x10, 0x5a0, 0x0};
        const std::vector<uintptr_t> AlwaysCandle = {0x1d92430, 0x18, 0x28, 0xa8, 0x1c8, 0xc};
        const std::vector<uintptr_t> WaxList = {0x1d92430, 0x18, 0x10, 0x638, 0x0};
        const std::vector<uintptr_t> FlowerList = {0x1d92430, 0x18, 0x10, 0x7b8, 0x0};
    } Offsets;

    std::string CurrentMapName = "";

public:

    void SetCollectEdenCandle(){

    }

    void SetCollectWingLight(){

    }

    void SetHiddenCloud(bool activate  = true){
        m.Write<bool>(m.GetPointer(Offsets.HiddenClouds), !activate);
    }

    void SetInfWing(bool activate  = true){
        m.Write<float>(m.GetPointer(Offsets.InfFly), activate ? 4.f : 2.5f);
    }

    void SetHiddenGrass(bool activate = true){
        m.Write<bool>(m.GetPointer(Offsets.HiddenGrass), !activate);
    }

    void SetDisableOnline(bool activate = true){
        m.Write<bool>(m.GetPointer(Offsets.DisableOnline), !activate);
    }

    void SetHiddenWater(bool activate = true){
        m.Write<bool>(m.GetPointer(Offsets.HiddenWater) + 0x0, !activate);
        m.Write<bool>(m.GetPointer(Offsets.HiddenWater) + 0x1, !activate);
    }

    void SetDisableGravity(bool activate = true){
        m.Write<bool>(m.GetPointer(Offsets.DisableGravity), !activate);
    }

    void SetLocalSpeed(float value){
        m.Write<float>(m.GetPointer(Offsets.WalkingSpeed), value * 3.5f);
        m.Write<float>(m.GetPointer(Offsets.DivingSpeed), value * 1.275f);
        m.Write<float>(m.GetPointer(Offsets.SwimmingSpeed), value * 0.65f);
    }

    void SetHiddenFog(bool activate){
        m.Write<bool>(m.GetPointer(Offsets.HiddenFog), activate);
    }

    ViewMatrix GetViewMatrix() {
        return m.Read<ViewMatrix>(m.GetPointer(Offsets.ViewMatrix));
    }

    std::string GetMapString() {
        return m.GetStrings(m.GetPointer(Offsets.MapString), 32);
    }

    void SetWingCount(uint32_t value) {
        m.Write<uint32_t>(m.GetPointer(Offsets.WingCount), value);
    }

    Vec3 GetLocalPlayerPos(){
        return m.Read<Vec3>(m.GetPointer(Offsets.LocalPlayerPos));
    }

    void SetLocalPlayerPos(Vec3 Pos) {
        m.Write<Vec3>(m.GetPointer(Offsets.LocalPlayerPos), Pos);
    }

    void RelativeTeleport(Vec3 Delta) {
        Vec3 Pos = GetLocalPlayerPos();
        Pos.x += Delta.x;
        Pos.y += Delta.y;
        Pos.z += Delta.z;
        SetLocalPlayerPos(Pos);
    }

    void InputTeleport(uint32_t Index = 0, float Radio = 1){
        Vec3 Delta;
        switch (Index) {
            case 0:
                Delta = {0.0f, 4.01f * Radio, 0.0f};
                break;
            case 1:
                Delta = {0.0f, -4.01f * Radio, 0.0f};
                break;
            case 2:
                Vec3 Angle = GetLocalPlayerAngle();
                Delta = {std::sin(Angle.x) * 4.01f * Radio, 0.f, std::cos(Angle.x) * 4.01f * Radio};
                break;
        }
        RelativeTeleport(Delta);
    }

    Vec3 GetLocalPlayerAngle(){
        return m.Read<Vec3>(m.GetPointer(Offsets.LocalPlayerAngle));
    }

    void SetLocalPlayerAngle(Vec3 Angle) {
        m.Write<Vec3>(m.GetPointer(Offsets.LocalPlayerAngle), Angle);
    }

    uint32_t GetMapID() {
        return m.Read<uint32_t>(m.GetPointer(Offsets.CurrentMapID));
    }

    void SetGlow(float value) {
       m.Write<float>(m.GetPointer(Offsets.Glow), value);
    }

    void SetCostume(int32_t id, int32_t index){
        m.Write<int32_t>(m.GetPointer(Offsets.Costume) + index, id);
    }

    Vec2 GetLocalPlayerHeight(bool IsReal = true) {
        Vec2 Height = m.Read<Vec2>(m.GetPointer(Offsets.LocalPlayerHeight));
        if (IsReal) Height.x = m.Read<float>(m.GetPointer(Offsets.LocalPlayerHeight) + 0x35c);
        return Height;
    }

    void SetLocalPlayerHeight(float height, float scale){
        m.Write<float>(m.GetPointer(Offsets.LocalPlayerHeight) + 0x0, height);
        if (scale) m.Write<float>(m.GetPointer(Offsets.LocalPlayerHeight) + 0x4, scale);
    }

    void SetInfFirework(bool activate = true){
        m.Write<float>(m.GetPointer(Offsets.InfFirework), activate ? 1000.f : 5.f);
    }

    void SetItemCount(uint32_t index, uint32_t value = 0) {
    
    }

    void SetNoCape(bool activate = true) {
        m.Write<uint8_t>(m.GetPointer(Offsets.NoCape), activate ? 255 : 0);
    }

    void SetMagic(int32_t id ,float sec = 300, uint32_t index = 0){
        uint32_t StartTime = std::time(nullptr);
        uint32_t EndTime = StartTime + (uint32_t)sec;
        m.Write<int32_t>(m.GetPointer(Offsets.Magic) + (0x38 * index) + 0x0, id);
        m.Write<uint32_t>(m.GetPointer(Offsets.Magic) + (0x38 * index) + 0x10, EndTime);
        m.Write<uint32_t>(m.GetPointer(Offsets.Magic) + (0x38 * index) + 0x18, StartTime);
        m.Write<uint8_t>(m.GetPointer(Offsets.Magic) + (0x38 * index) + 0x25, 0);
    }

    void SetOpenCloset(uint32_t index) {
        m.Write<uint8_t>(m.GetPointer(Offsets.OpenCloset) - 0x3c, 1);
        m.Write<uint8_t>(m.GetPointer(Offsets.OpenCloset) - 0x4, 0);
        m.Write<uint8_t>(m.GetPointer(Offsets.OpenCloset) + 0x0, index);
        m.Write<uint8_t>(m.GetPointer(Offsets.OpenCloset) + 0x4, 1);
    }

    void SetGlobalSpeed(float value){
        m.Write<float>(m.GetPointer(Offsets.GlobalSpeed), value);
    }

    Vec3 GetViewAngle(){
        return m.Read<Vec3>(m.GetPointer(Offsets.ViewAngle));
    }

    void SetGetViewAngle(Vec3 Angle){
        m.Write<Vec3>(m.GetPointer(Offsets.ViewAngle), Angle);
    }

    void SetBurnCandles(bool activate = true){
        uintptr_t CandleList = m.GetPointer(Offsets.CandleList);
        uint16_t count = m.Read<uint16_t>(CandleList + 0x28);
        for (int i = 0; i < count; i++) {
            uintptr_t address = CandleList + 0xe0 + (i * 0x1d0);
            if(m.Read<float>(address + 0x128) != 0) continue;
            m.Write<float>(address + 0x128, (float)activate);
        }
    }

    void SetAlwaysCandle(bool activate = true){
        m.Write<bool>(m.GetPointer(Offsets.AlwaysCandle), activate);
    }

    void SetBurnFlowers(bool activate = true){
        uintptr_t FlowerList = m.GetPointer(Offsets.FlowerList);
        for (int i = 0; i < 0x128; i++) {
            uintptr_t address = FlowerList + 0x924 + (i * 0x8);
            float value = m.Read<float>(address);
            if (value < 0.0f || value > 1.0f) continue;
             m.Write<float>(address, (float)!activate);
        }
    }

    void SetCollectWaxs(){

    }

    bool IsChangeCurrentMapName(){
        const std::string& NewMapName = GetMapString();
        if(CurrentMapName != NewMapName){
            CurrentMapName = NewMapName;
            return true;
        }
        return false;
    }

};
