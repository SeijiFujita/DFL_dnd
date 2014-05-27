/++
 dfl.enum_format.d

// See the included license.txt for copyright and license details.

++/
module dfl.enum_format;

import dfl.base;
import dfl.internal.winapi;
import dfl.internal.wincom;

import dfl.debuglog;

import core.atomic;
import core.memory;


//@----------------------------------------------------------------------------
abstract class xComObject : IUnknown
{
    shared(LONG) _refCount;
    
    HRESULT QueryInterface(IID* riid, void** ppv)
    {
        if (*riid == IID_IUnknown)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }
        *ppv = null;
        return E_NOINTERFACE;
    }

    ULONG AddRef()
    {
        LONG lRef = atomicOp!"+="(_refCount, 1);
        
        outLog("xComObject:AddRef:lRef:", cast(long)lRef);
        
        if (lRef == 1) {
            GC.addRoot(cast(void*)this);
        }
        return lRef;
    }

    ULONG Release()
    {
        LONG lRef = atomicOp!"-="(_refCount, 1);
        
        outLog("xComObject:Release:lRef:", cast(long)lRef);
        
        if (lRef == 0) {
            GC.removeRoot(cast(void*)this);
        }
        return cast(ULONG)lRef;
    }
}  // xComObject

//@----------------------------------------------------------------------------

class EnumFormatEtc : xComObject, IEnumFORMATETC
{
private:
    uint _index;
    FORMATETC[] _formatEtc;

public:
    //
    this(FORMATETC[] fmt)
    {
        outLog("EnumFormatEtc:this");
        _index = 0;
        foreach (v ; fmt)
            _formatEtc ~= DuplicateFormatEtc(v);
    }
    ~this()
    {
        outLog("EnumFormatEtc:~this");
    }
    //
    extern (Windows)
    override HRESULT QueryInterface(IID* riid, void** ppv)
        {
        outLog("EnumFormatEtc:QueryInterface");
        if (*riid == IID_IEnumFORMATETC)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }
        return super.QueryInterface(riid, ppv);
    }
/++
  MSDN: If the returned FORMATETC structure contains a non-null
  ptd member, then the caller must free this using CoTaskMemFree.

  itemCount で指定された数だけFORMATETC構造体を pf にコピーします。
++/
    extern (Windows)
    HRESULT Next(ULONG itemCount, FORMATETC* pf, ULONG* itemsCopied)
    {
        outLog("EnumFormatEtc:Next");
        if (itemCount <= 0 || pf is null || _index >= _formatEtc.length)
            return S_FALSE;
        
        // itemCount が1 の時だけitemsCopied はNULLに出来る?
        if (itemCount != 1 && itemsCopied is null )
            return S_FALSE;
        
        if (itemsCopied != null)
            *itemsCopied = 0;
        
        ULONG copyCount = 0;
        while (_index < _formatEtc.length && copyCount < itemCount)
        {
            // pf[copyCount] = DuplicateFormatEtc(_formatEtc[_index]);
            pf[copyCount] = _formatEtc[_index];
            copyCount++;
            _index++;
        }
        if (itemsCopied != null)
            *itemsCopied = copyCount;
        // did we copy all that was requested?
		outLog("copyCount:", copyCount);
		outLog("itemCount:", itemCount);
		outLog("_index:", _index);
        return copyCount == itemCount ? S_OK : S_FALSE;
    }

/++
  読みとり位置(_index)をitemCount分スキップします
++/
    extern (Windows)
    HRESULT Skip(ULONG itemCount)
    {
        outLog("EnumFormatEtc:Skip");
        
        while(_index < _formatEtc.length && itemCount > 0) {
            _index++;
            itemCount--;
        }
        return (itemCount == 0)? S_OK : S_FALSE;
    }
    
/++
  読みとり位置(_index)を先頭に戻します
++/
    extern (Windows)
    HRESULT Reset()
    {
        outLog("EnumFormatEtc:Reset");
        _index = 0;
        return S_OK;
    }
    
    // Clone this enumerator.
    // ppEnumFormatEtc を複製します
    extern (Windows)
    HRESULT Clone(IEnumFORMATETC* ppEnumFormatEtc)
    {
        outLog("EnumFormatEtc:Clone");
        if (_formatEtc.length == 0 || ppEnumFormatEtc is null)
            return E_INVALIDARG;
        
        auto obj = new EnumFormatEtc(_formatEtc);
        if (obj is null)
            return E_OUTOFMEMORY;
        
        obj.AddRef();
        *ppEnumFormatEtc = obj;
        return S_OK;
    }

private:
    private void releaseMemory()
    {
        outLog("releaseMemory");
        foreach (v ; _formatEtc) {
            if (v.ptd)
                CoTaskMemFree(v.ptd);
        }
    }
}
//@----------------------------------------------------------------------------
/** Perform a deep copy of a FORMATETC structure. */
FORMATETC DuplicateFormatEtc(FORMATETC source)
{
    FORMATETC res;
    res = source;
    
    outLog("DuplicateFormatEtc");
    
    // duplicate memory for the DVTARGETDEVICE if necessary
    if (source.ptd)
    {
        res.ptd = cast(DVTARGETDEVICE*)CoTaskMemAlloc(DVTARGETDEVICE.sizeof);
        *(res.ptd) = *(source.ptd);
    }
    return res;
}


// eof
