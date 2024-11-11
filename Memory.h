#import <substrate.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#include <vector>
#include <cstdint>

#define HOOK(offset, ptr, orig) MSHookFunction((void *)(Memory::GetBaseAddr() + offset), (void *)ptr, (void **)&orig)

struct ModuleInfo {
    const struct mach_header *header;
    const char *name;
    uintptr_t address;
};

struct ViewMatrix
{
    float Matrix[16]{};
};

struct Vec2
{
    float x = 0.0f, y = 0.0f;

    Vec2(float x = 0.0f, float y = 0.0f) : x(x), y(y) {}
};

struct Vec3
{
    float x = 0.0f, y = 0.0f, z = 0.0f;

    Vec3(float x = 0.0f, float y = 0.0f, float z = 0.0f) : x(x), y(y), z(z) {}
};

struct Vec4
{
    float x = 0.0f, y = 0.0f, z = 0.0f, w = 0.0f;

    Vec4(float x = 0.0f, float y = 0.0f, float z = 0.0f, float w = 0.0f) : x(x), y(y), z(z), w(w) {}
};

class Memory
{
public:

    uintptr_t BaseAddr = GetModuleHandles()[0].address;

    Memory() {
        //
    }

    template <typename T>
    T Read(const uintptr_t &address) const noexcept
    {
        T result;
        vm_size_t size = sizeof(T);
        vm_read_overwrite(mach_task_self(), (mach_vm_address_t)address, size, (mach_vm_address_t)&result, &size);
        return result;
    }

    template <typename T>
    void Write(const uintptr_t &address, const T &value) const noexcept
    {
        vm_write(mach_task_self(), (mach_vm_address_t)address, (vm_offset_t)&value, sizeof(T));
    }

    uintptr_t GetPointer(const std::vector<uintptr_t>& offsets) const noexcept {
        uintptr_t address = BaseAddr + offsets[0];
        for (size_t i = 1; i < offsets.size(); ++i) {
            address = Read<uintptr_t>(address) + offsets[i];
        }
        return address;
    }

    std::string GetStrings(const uintptr_t &address, size_t length) const noexcept {
        std::string result;
        if (address != 0) {
            for (size_t i = 0; i < length; ++i) {
                char c = Read<char>(address + i);
                if (c == '\0') break;
                result += c;
            }
        }
        return result;
    }

    std::vector<ModuleInfo> GetModuleHandles(){
        std::vector<ModuleInfo> modules;
        for (uint32_t i = 0; i < _dyld_image_count(); i++)
        {
            ModuleInfo info;
            info.header = _dyld_get_image_header(i);
            info.name = _dyld_get_image_name(i);
            info.address = _dyld_get_image_vmaddr_slide(i) + 0x100000000;
            modules.push_back(info);
        }
        return modules;
    }

    bool WorldToScreen(Vec3 Pos, Vec2 &Screen, float Matrix[16], uint32_t WWidth, uint32_t WHeight)
    {
        Vec4 clipCoords = {};

        clipCoords.x = Pos.x * Matrix[0] + Pos.y * Matrix[4] + Pos.z * Matrix[8] + Matrix[12];
        clipCoords.y = Pos.x * Matrix[1] + Pos.y * Matrix[5] + Pos.z * Matrix[9] + Matrix[13];
        clipCoords.z = Pos.x * Matrix[2] + Pos.y * Matrix[6] + Pos.z * Matrix[10] + Matrix[14];
        clipCoords.w = Pos.x * Matrix[3] + Pos.y * Matrix[7] + Pos.z * Matrix[11] + Matrix[15];

        if (clipCoords.w < 0.1f)
        {
            clipCoords.w = 1.0f;
        }

        Vec3 TranslatedCoords;
        TranslatedCoords.x = clipCoords.x / clipCoords.w;
        TranslatedCoords.y = clipCoords.y / clipCoords.w;
        TranslatedCoords.z = clipCoords.z / clipCoords.w;

        Screen.x = (WWidth / 2 * TranslatedCoords.x) + (TranslatedCoords.x + WWidth / 2);
        Screen.y = -(WHeight / 2 * TranslatedCoords.y) + (TranslatedCoords.y + WHeight / 2);

        return true;
    }

};
