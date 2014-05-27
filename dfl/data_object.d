/++

// See the included license.txt for copyright and license details.

++/

module dfl.data_object;

import dfl.internal.dlib;
import dfl.base;
import dfl.internal.winapi;
import dfl.internal.wincom;
import dfl.internal.utf;

//private import dfl.application;
//private import dfl.internal.com;

import dfl.enum_format;
import dfl.debuglog;

import std.string;


//@----------------------------------------------------------------------------
// Utilitys

/++
ansi -> utf16 -> utf8

ansi is char size
utf8 is char size
utf16 is wchar size

++/

enum : uint {
	CP_ACP,
	CP_OEMCP,
	CP_MACCP,
	CP_THREAD_ACP, // =     3
	CP_SYMBOL         =    42,
	CP_UTF7           = 65000,
	CP_UTF8           = 65001
}

string ANSItoUTF8(string ansi)
{
    int  len;
    char[] utf8;
    wchar[] utf16;
    
    outLog("ANSItoUTF8");
    outdumpLog(cast(void*)ansi, ansi.length);
    len = MultiByteToWideChar(CP_ACP, 0, ansi.toStringz, -1, null, 0);
    utf16.length = len; // null terminate
    MultiByteToWideChar(CP_ACP, 0, ansi.toStringz, -1, utf16.ptr, len);
    outdumpLog(cast(void*)utf16, utf16.length *2);
    
    len = WideCharToMultiByte(CP_UTF8, 0, utf16.ptr, -1, null, 0, null, null);
    utf8.length = len;
    WideCharToMultiByte(CP_UTF8, 0, utf16.ptr, -1, utf8.ptr, len, null, null);
    utf8.length--; // clear null termination
    outdumpLog(cast(void*)utf8, utf8.length);
    
    return cast(string) utf8.dup;
}
string UTF8toANSI(string utf8)
{
    int  len;
    char[] ansi;
    wchar[] utf16;
    
    outLog("UTF8toANSI");
    outdumpLog(cast(void*)utf8, utf8.length);
    len = MultiByteToWideChar(CP_UTF8, 0, utf8.toStringz, -1, null, 0);
    utf16.length = len; // null terminate
    MultiByteToWideChar(CP_UTF8, 0, utf8.toStringz, -1, utf16.ptr, len);
    outdumpLog(cast(void*)utf16, utf16.length *2);
    
    len = WideCharToMultiByte(CP_ACP, 0, utf16.ptr, -1, null, 0, null, null);
    ansi.length = len;
    WideCharToMultiByte(CP_ACP, 0, utf16.ptr, -1, ansi.ptr, len, null, null);
    ansi.length--; // clear null termination
    outdumpLog(cast(void*)ansi, ansi.length);
    return cast(string) ansi.dup;
}
wstring UTF8toUTF16(string utf8)
{
    int  len;
    wchar[] utf16;
    
    outLog("utf8 -> utf16");
	outdumpLog(cast(void*)utf8, utf8.length);
    len = MultiByteToWideChar(CP_UTF8, 0, utf8.toStringz, -1, null, 0);
    utf16.length = len + 1; // null terminate
    MultiByteToWideChar(CP_UTF8, 0, utf8.toStringz, -1, utf16.ptr, len);
	outdumpLog(cast(void*)utf16, utf16.length * 2);
    
    return cast(wstring) utf16.dup;
}

wchar* toWStringz(wstring ws)
{
    assert(ws.length, "toWStringz");
    auto copy = new wchar[ws.length + 1];
    copy[0 .. ws.length] = ws[];
    copy[ws.length] = 0;
    
    return copy.ptr;
}
string UTF16toUTF8(wstring utf16)
{
    int  len;
    
    outLog("utf16 -> utf8");
	outdumpLog(cast(void*)utf16, utf16.length * 2);
    len = WideCharToMultiByte(CP_UTF8, 0u, utf16.toWStringz, -1, null, 0, null, null);
    
    outLog("UTF16toUTF8.len: ", len);
    char[] utf8;
    utf8.length = len + 1;
    WideCharToMultiByte(CP_UTF8, 0u, utf16.toWStringz, -1, utf8.ptr, len, null, null);
    utf8.length--; // clear null termination
	outdumpLog(cast(void*)utf8, utf8.length);
    
    return cast(string) utf8.dup;
}


int pszLen(const char *s)
{
    if (s is null)
        return 0;
    
    char* src = cast(char*)s;
    while (1) {
        if (!*src)
            break;
        
        src++;
    }
    return src - s;
}

int pwszLen(const wchar *s)
{
    if (s is null)
        return 0;
    
    wchar* src = cast(wchar*)s;
    while (1) {
        if (!*src)
            break;
        
        src++;
    }
    return src - s;
}

void pszCopy(ref char[] dest, const char *src)
{
    uint n = pszLen(src);
    dest[0 .. n] = src[0 .. n];
}

string pszToString(const char *src)
{
    uint len = pszLen(src);
    if (len == 0)
        return "";
    
    char[] result = new char[len];
    result[0 .. len] = src[0 .. len];
    return cast(string)result;
}

wstring pwszToString(const wchar *src)
{
    uint len = pwszLen(src);
    if (len == 0)
        return "";
    
    wchar[] result = new wchar[len];
    result[0 .. len] = src[0 .. len];
    return cast(wstring)result;
}

int StringToPsz(string src, char *dest)
{
    dest[0 .. src.length] = src[];
    dest[src.length] = '\0';
    return src.length;
}



//@----------------------------------------------------------------------------


struct ObjectData
{
private:
    FORMATETC _objformat;
    STGMEDIUM _objmedium;

public:
    void Set(FORMATETC pf, STGMEDIUM pm)
    {
        _objformat = pf;
        _objmedium = pm;
    }
    void Set(FORMATETC* pf, STGMEDIUM* pm)
    {
        _objformat = *pf;
        _objmedium = *pm;
    }
	
    bool Set(FORMATETC* pf, STGMEDIUM* pm, bool fRelease)
    {
        _objformat = *pf;
        if (fRelease) {
            _objmedium = *pm;
			ReleaseStgMedium(pm);
            return	true;
        }
        else {
            return DuplicateMedium(&_objmedium, pf, pm);
        }
    }
    
    bool match(FORMATETC f)
    {
        bool result = false;
        if (_objformat.tymed == f.tymed
            && _objformat.cfFormat == f.cfFormat
            && _objformat.dwAspect == f.dwAspect)
        {
            result = true;
        }
        return result;
    }

    bool DuplicateMedium(STGMEDIUM *pdest, FORMATETC* pf, STGMEDIUM *pm)
    {
        HANDLE	hVoid;
        
        outLog("ObjectData:DuplicateMedium");
        switch (pm.tymed) {
        case TYMED.TYMED_HGLOBAL:
            hVoid = OleDuplicateData(cast(void*)pm.hGlobal, cast(ushort)pf.cfFormat, cast(UINT)null);
            pdest.hGlobal = cast(HGLOBAL)hVoid;
            break;
        case TYMED.TYMED_FILE:
            hVoid = OleDuplicateData(cast(void*)pm.lpszFileName, cast(ushort)pf.cfFormat, cast(UINT)null);
            pdest.lpszFileName = cast(LPOLESTR)hVoid;
            break;
//
//        case TYMED.TYMED_GDI:
//            hVoid = OleDuplicateData(cast(void*)pm.hBitmap, cast(ushort)pf.cfFormat, cast(UINT)null);
//            pdest.hBitmap = cast(HBITMAP)hVoid;
//            break;
//        case TYMED.TYMED_MFPICT:
//            hVoid = OleDuplicateData(cast(void*)pm.hMetaFilePict, cast(ushort)pf.cfFormat, cast(UINT)null);
//            pdest.hMetaFilePict = cast(HMETAFILEPICT)hVoid;
//            break;
//        case TYMED.TYMED_ENHMF:
//            hVoid = OleDuplicateData(cast(void*)pm.hEnhMetaFile, cast(ushort)pf.cfFormat, cast(UINT)null);
//            pdest.hEnhMetaFile = cast(HENHMETAFILE)hVoid;
//            break;
//        case TYMED.TYMED_NULL:
//            hVoid = cast(HANDLE)1; //エラーにならないように
//            break;
//        case TYMED.TYMED_ISTREAM:
//        case TYMED.TYMED_ISTORAGE:
//
        default:
			assert(0,"ObjectData:DuplicateMedium");
        }
        
        pdest.tymed = pm.tymed;
        pdest.pUnkForRelease = pm.pUnkForRelease;
        
        if (pm.pUnkForRelease !is null)
            pm.pUnkForRelease.AddRef();
        
        return true;
    }
} // ObjectData




class comDataObject : xComObject, IDataObject
{
private:
    ObjectData[] _dataStores;

public:
    this() {
        outLog("comDataObject:this");
    }
    
    ~this()
    {
        _dataStores.length = 0;
        outLog("comDataObject:~this");
    }
    
    this(FORMATETC pf, STGMEDIUM pm)
    {
        add(pf, pm);
    }
    void add(FORMATETC pf, STGMEDIUM pm)
    {
        outLog("comDataObject:add");
        
        ObjectData fs;
        fs.Set(pf, pm);
        _dataStores ~= fs;
    }
    
 	/++
     Duplicate the memory helt at the global memory handle,
     and return the handle to the duplicated memory.
     ++/
    HGLOBAL DuplicateGlobalMem(HGLOBAL hMem)
    {
        DWORD len = GlobalSize(hMem);
        outLog("DuplicateGlobalMem.GlobalSize: ", len);
        HGLOBAL dest = GlobalAlloc(GHND, len);
        if (dest is null)
            return null;
        
        char* src = cast(char*) GlobalLock(hMem);
        char* buf = cast(char*) GlobalLock(dest);
        buf[0 .. len] = src[0 .. len];
        
        GlobalUnlock(dest);
        GlobalUnlock(hMem);
        return dest;
    }

//@--------------------------------------------------------------------
// IDataObject interface
    extern (Windows)
    override HRESULT QueryInterface(IID* riid, void** ppv)
    {
        outLog("comDataObject:QueryInterface");
        if (*riid == IID_IDataObject)
        {
            *ppv = cast(void*)cast(IUnknown)this;
            AddRef();
            return S_OK;
        }
        return super.QueryInterface(riid, ppv);
    }

/++
  Find the data of the format pFormatEtc and if found store
  it into the storage medium pMedium.

  1. IDropTarget.dragDropでGetDataは呼び出される(データ取得するため)
  2. FORMATETC* pFormatEtc 指定されたデータと同じ物があったら
     STGMEDIUM* pMedium に必ずGrobalAlloc で複製します
  3. GetData を呼び出したIDropTarget.dragDrop は
     ReleaseStgMedium(&medium);
     で必ず開放する(他のアプリケーションも同様)
  
++/
    extern (Windows)
    HRESULT GetData(FORMATETC* pFormatEtc, STGMEDIUM* pMedium)
    {
        outLog("comDataObject:GetData");
        if (pFormatEtc is null || pMedium is null) {
            return E_INVALIDARG;
        }
        if (!(DVASPECT.DVASPECT_CONTENT & pFormatEtc.dwAspect))
            return DV_E_DVASPECT;
        
        // try to match the requested FORMATETC with one of our supported formats
        ObjectData fs;
        bool matchFlag;
        foreach (v ; _dataStores) {
            matchFlag = v.match(*pFormatEtc);
            if (matchFlag) {
                fs = v;
                break;
            }
        }
        if (matchFlag == false)
            return DV_E_FORMATETC;  // pFormatEtc is invalid
        
        // found a match - transfer the data into the supplied pMedium
        // store the type of the format, and the release callback (null).
        pMedium.tymed = fs._objformat.tymed;
        pMedium.pUnkForRelease = null;
        
        // duplicate the memory
        switch (fs._objformat.tymed) {
        case TYMED.TYMED_HGLOBAL:
            pMedium.hGlobal = DuplicateGlobalMem(fs._objmedium.hGlobal);
            return S_OK;
            
        default:
            // todo: we should really assert here since we need to handle
            // all the data types in our formatStores if we accept them
            // in the constructor.
            return DV_E_FORMATETC;
        }
    }

    extern (Windows)
    HRESULT GetDataHere(FORMATETC* pFormatEtc, STGMEDIUM* pMedium)
    {
        outLog("comDataObject:GetDataHere");
        // GetDataHere is only required for IStream and IStorage mediums
        // It is an error to call GetDataHere for things like HGLOBAL and other clipboard formats
        // OleFlushClipboard
        return DATA_E_FORMATETC;
    }

/++
  Called to see if the IDataObject supports the specified format of data

  指定された形式のデータが有るか無いかを返す関数です。
  データを返さない GetData です。
  DropTarget.QueryDataObject でも呼んでいます
++/
    extern (Windows)
    HRESULT QueryGetData(FORMATETC* pf)
    {
        outLog("comDataObject:QueryGetData:_dataStores.length: ", _dataStores.length);
        bool matchFlag;
        foreach (v ; _dataStores) {
            matchFlag = v.match(*pf);
            if (matchFlag) {
                break;
            }
        }
        return matchFlag ? S_OK : DV_E_FORMATETC;
    }

/++
  MSDN: Provides a potentially different but logically equivalent
  FORMATETC structure. You use this method to determine whether two
  different FORMATETC structures would return the same data,
  removing the need for duplicate rendering.
++/
    extern (Windows)
    HRESULT GetCanonicalFormatEtc(FORMATETC* pFormatEtc, FORMATETC* pFormatEtcOut)
    {
        /*
            MSDN: For data objects that never provide device-specific renderings,
            the simplest implementation of this method is to copy the input
            FORMATETC to the output FORMATETC, store a NULL in the ptd member of
            the output FORMATETC, and return DATA_S_SAMEFORMATETC.
        */
        outLog("comDataObject:GetCanonicalFormatEtc");
        *pFormatEtcOut = DuplicateFormatEtc(*pFormatEtc);
        pFormatEtcOut.ptd = null;
        return DATA_S_SAMEFORMATETC;
    }

/++
  FORMATETC* pFormatEtc, STGMEDIUM* pMedium のデータを追加する関数です。
  引数のBOOL fRelease が
   TRUEの場合: 呼び出し側がデータを保持するのでSetDataは不要になったら開放する。
   FALSEの場合: 呼び出し側はデータを破棄するのでSetData はデータを複製して格納します。
  

BOOL fRelease:
If TRUE, the data object called, which implements SetData, owns the 
storage medium after the call returns. This means it must free the medium after 
it has been used by calling the ReleaseStgMedium function. 

If FALSE, the caller retains ownership of the storage medium and the data object
 called uses the storage medium for the duration of the call only.

++/
    extern (Windows)
    HRESULT SetData(FORMATETC* pFormatEtc, STGMEDIUM* pMedium, BOOL fRelease)
    {
        outLog("comDataObject:SetData");
//        return E_NOTIMPL;
        
        if (pFormatEtc is null || pMedium is null)
            return E_INVALIDARG;
        
        outLog("comDataObject:SetData:1");
        bool matchFlag = false;
        foreach (v ; _dataStores) {
            matchFlag = v.match(*pFormatEtc);
            if (matchFlag) {
                break;
            }
        }
        outLog("comDataObject:SetData:2");
 		if (matchFlag == false) {
            ObjectData fs;
            if (!fs.Set(pFormatEtc, pMedium, fRelease == TRUE))
                return E_OUTOFMEMORY;
            _dataStores ~= fs;
            outLog("_dataStores.length: ", _dataStores.length);
        }
        outLog("comDataObject:SetData:end");
        return S_OK;
    }

/++
  Create and store an object into ppEnumFormatEtc which enumerates the
  formats supported by this comDataObject instance.
++/
    extern (Windows)
    HRESULT EnumFormatEtc(DWORD dwDirection, IEnumFORMATETC* ppEnumFormatEtc)
    {
        outLog("comDataObject:EnumFormatEtc");
        switch (dwDirection) {
        case DATADIR.DATADIR_GET:
        {
            if (_dataStores.length == 0 || ppEnumFormatEtc is null) {
                return E_INVALIDARG;
            }
            
            FORMATETC[] fe;
            foreach (v ; _dataStores)
                fe ~= v._objformat;
            
            outLog("comDataObject:EnumFormatEtc:fe.length=", fe.length);
            auto obj = new dfl.enum_format.EnumFormatEtc(fe);
            obj.AddRef();
            *ppEnumFormatEtc = obj;
            return S_OK;
        }
        
        // not supported.
        case DATADIR.DATADIR_SET:
        default:
            return E_NOTIMPL;
        }
    }
/++
++/
    extern (Windows)
    HRESULT DAdvise(FORMATETC* pFormatEtc, DWORD advf, IAdviseSink* pAdvSink, DWORD* pdwConnection)
    {
        outLog("comDataObject:DAdvise");
        return OLE_E_ADVISENOTSUPPORTED;
    }
    extern (Windows)
    HRESULT DUnadvise(DWORD dwConnection)
    {
        outLog("comDataObject:DUnadvise");
        return OLE_E_ADVISENOTSUPPORTED;
    }
    extern (Windows)
    HRESULT EnumDAdvise(IEnumSTATDATA* ppEnumAdvise)
    {
        outLog("comDataObject:EnumDAdvise");
        return OLE_E_ADVISENOTSUPPORTED;
    }
//@--------------------------------------------------------------------
}

//@----------------------------------------------------------------------------
class DataObject
{
private:
    IDataObject _dataObject;

public:
    this()
    {
        _dataObject = new comDataObject;
	}
    this(IDataObject data)
    {
        _dataObject = data;
    }
    ~this()
    {
        // delete _dataObject;
    }
    void createDataObject()
    {
        _dataObject = new comDataObject;
    }
    IDataObject getDataObject()
    {
        return _dataObject;
	}
//@--------------------------------------------------------------------
public:

    void setFormatetc(CLIPFORMAT cfFormat, ref FORMATETC pf)
    {
        pf.cfFormat = cfFormat;
        pf.dwAspect = DVASPECT.DVASPECT_CONTENT;
        pf.lindex = -1;
        pf.ptd = null;
        pf.tymed = TYMED.TYMED_HGLOBAL;
    }
    
    bool queryData(CLIPFORMAT cfFormat)
    {
        FORMATETC fmtetc;
        fmtetc.cfFormat = cfFormat;
        fmtetc.dwAspect = DVASPECT.DVASPECT_CONTENT;
        fmtetc.lindex = -1;
        fmtetc.ptd = null;
        fmtetc.tymed = TYMED.TYMED_HGLOBAL;
        return _dataObject.QueryGetData(&fmtetc) == S_OK ? true : false;
    }
    
    void SetupMedium(CLIPFORMAT cfFormat, HANDLE hObject, ref FORMATETC pf, ref STGMEDIUM pm)
    {
        outLog("DataObject.SetupMedium");
        pf.cfFormat = cfFormat;
        pf.dwAspect = DVASPECT.DVASPECT_CONTENT;
        pf.lindex = -1;
        pf.ptd = null;
        pf.tymed = TYMED.TYMED_HGLOBAL;
        
        pm.hGlobal = hObject;
        pm.tymed = TYMED.TYMED_HGLOBAL;
        pm.pUnkForRelease = null;
	}
//@--------------------------------------------------------------------
	bool queryText()
	{
		return queryAnsiText();
	}
    string getText()
    {
		return ANSItoUTF8(getAnsiText());
	}
    bool setText(string text)
    {
    	return setAnsiText(UTF8toANSI(text));
	}
//@--------------------------------------------------------------------
    HGLOBAL CreateText(string text)
    {
        HGLOBAL hText = GlobalAlloc(GHND, text.length + 1);
        if (hText is null)
            return null;
        
        char*  buf = cast(char*) GlobalLock(hText);
        buf[0 .. text.length] = text[];
        buf[text.length] = '\0';
        
        GlobalUnlock(hText);
        return hText;
    }

/++
Windows Drag and Drop の
CF_TEXT は ansi or MBCS 
CF_UNICODE はUTF16 

DFL のstring は ansi or UTF8 というか漢字を扱うならばUTF8です
したがってCF_TEXT を表示する場合は
UTF8 にコンバートする事が必要です。

++/
    // Ansi or MBCS
    bool queryAnsiText()
    {
        return queryData(CF_TEXT);
    }
    // Ansi or MBCS
    string getAnsiText()
    {
        string result;
        STGMEDIUM medium;
        FORMATETC fmtetc;
        setFormatetc(CF_TEXT, fmtetc);
        
        outLog("DataObject.getAnsiText");
        if (_dataObject.GetData(&fmtetc, &medium) == S_OK) {
            char *buf = cast(char*)GlobalLock(medium.hGlobal);
            result = pszToString(buf);
            GlobalUnlock(medium.hGlobal);
            ReleaseStgMedium(&medium);
        }
        return result;
    }
    // Ansi or MBCS
    bool setAnsiText(string text)
    {
        outLog("DataObject.setAnsiText:", text);
        HGLOBAL hObject = CreateText(text);
        if (hObject == null) {
            return false;
        }
        ObjectData fs;
        FORMATETC fmtetc;
        STGMEDIUM stgmed;
        
        SetupMedium(CF_TEXT, hObject, fmtetc, stgmed);
        
        _dataObject.SetData(&fmtetc, &stgmed, 0);
        
        return true;
    }

//@--------------------------------------------------------------------
    HGLOBAL CreateUnicodeText(wstring text)
    {
        uint byteSize = text.length * 2;
        HGLOBAL hText = GlobalAlloc(GHND, byteSize + 1);
        if (hText is null)
            return null;
        
        wchar*  buf = cast(wchar*) GlobalLock(hText);
        buf[0 .. text.length] = text[];
        buf[text.length] = 0;
        
        GlobalUnlock(hText);
        outLog("CreateUnicodeText");
        outdumpLog(cast(void*) buf, byteSize);
        return hText;
    }





    // UTF16
    bool queryUnicodeText()
    {
        return queryData(CF_UNICODETEXT);
    }

    // UTF16
    wstring getUnicodeText()
    {
        wstring result;
        STGMEDIUM medium;
        FORMATETC fmtetc;
        setFormatetc(CF_UNICODETEXT, fmtetc);
        
        outLog("getUnicodeText");
        if (_dataObject.GetData(&fmtetc, &medium) == S_OK) {
            wchar *buf = cast(wchar*)GlobalLock(medium.hGlobal);
            result = pwszToString(buf);
            GlobalUnlock(medium.hGlobal);
            ReleaseStgMedium(&medium);
        }
        return result;
    }
	
    // UTF16 Only
    bool setUnicodeText(wstring text)
    {
        HGLOBAL hObject = CreateUnicodeText(text);
        if (hObject == null) {
            return false;
        }
        FORMATETC fmtetc;
        STGMEDIUM stgmed;
        SetupMedium(CF_UNICODETEXT, hObject, fmtetc, stgmed);
        
        _dataObject.SetData(&fmtetc, &stgmed, 0);
        return true;
    }
//@--------------------------------------------------------------------
/++
struct DROPFILES {
	DWORD pFiles;
	POINT pt;
	BOOL fNC;
	BOOL fWide;
}
alias DROPFILES* LPDROPFILES;
++/
    string[] getHDropString(void[] value)
    {
        if (value.length <= DROPFILES.sizeof)
            return null;
        
        string[] result;
        DROPFILES* df;
        size_t iw, startiw;
        
        df = cast(DROPFILES*)value.ptr;
        if (df.pFiles < DROPFILES.sizeof || df.pFiles >= value.length)
            return null;
        
        if (df.fWide) { // UTF16 Unicode.
            wstring uni = cast(wstring)((value.ptr + df.pFiles)[0 .. value.length]);
            for (iw = startiw = 0;; iw++) {
                if (!uni[iw]) {
                    if (startiw == iw)
                        break;
                    result ~= fromUnicode(uni.ptr + startiw, iw - startiw);
                    assert(result[result.length - 1].length);
                    startiw = iw + 1;
                }
            }
        }
        else { // ANSI.
            string ansi = cast(string)((value.ptr + df.pFiles)[0 .. value.length]);
            for (iw = startiw = 0;; iw++) {
                if (!ansi[iw]) {
                    if (startiw == iw)
                        break;
                    result ~= fromAnsi(ansi.ptr + startiw, iw - startiw);
                    assert(result[result.length - 1].length);
                    startiw = iw + 1;
                }
            }
        }
        return result;
    }
    // UTF8
    HDROP CreateHDrop(string[] filesPath)
    {
        HDROP hDrop;
        int btotal = 0;
        int ucount = 0;
        
        foreach (i ; 0 .. filesPath.length) {
            btotal += MultiByteToWideChar(CP_UTF8, 0, filesPath[i].toStringz(), -1, null, 0) * wchar.sizeof;
        }
        hDrop = cast(HDROP)GlobalAlloc(GHND, DROPFILES.sizeof + btotal + 2);
        if (hDrop is null)
            return null;
        
        LPDROPFILES lpDropFile;
        lpDropFile  = cast(LPDROPFILES) GlobalLock(hDrop);
        lpDropFile.pFiles = DROPFILES.sizeof;
        lpDropFile.pt.x   = 0;
        lpDropFile.pt.y   = 0;
        lpDropFile.fNC    = false;
        lpDropFile.fWide  = true;
        
        // 構造体の後ろにファイル名のリストをコピーする。(filename\0filename\0filename\0\0\0)
        wchar *buf = cast(wchar *) &lpDropFile[1];
        int count;
        foreach (i ; 0 .. filesPath.length) {
            count = MultiByteToWideChar(CP_UTF8, 0, filesPath[i].toStringz(), -1, buf, btotal);
            buf += count;
        }
        *buf++ = 0;
        *buf   = 0;
        
        GlobalUnlock(hDrop);
        return hDrop;
    }

    bool queryDropFile()
    {
        return queryData(CF_HDROP);
    }

    string[] getDropFile()
    {
        string[] Files;
        STGMEDIUM medium;
        FORMATETC fmtetc;
        setFormatetc(CF_HDROP, fmtetc);
        
        outLog("DataObject.getDropFile");
        if (_dataObject.GetData(&fmtetc, &medium) == S_OK) {
            // Files = getHDropString(cast(void*)medium.hGlobal);
            // ReleaseStgMedium(&medium);
            
            uint countFile = dragQueryFile(cast(HDROP)medium.hGlobal);
            outLog("countFile: ", countFile);
            foreach (i ; 0 .. countFile) {
                string s = dragQueryFile(cast(HDROP)medium.hGlobal, i);
                Files ~= s;
            }
            ReleaseStgMedium(&medium);
        }
        foreach (v ; Files)
            outLog(v);
        
        return Files;
    }

    bool setDropFile(string[] filesList)
    {
        HDROP hObject = CreateHDrop(filesList);
        if (hObject == null) {
            outLog("hObject == null");
            return false;
        }
        
        FORMATETC fmtetc;
        STGMEDIUM stgmed;
        SetupMedium(CF_HDROP, hObject, fmtetc, stgmed);
        
        _dataObject.SetData(&fmtetc, &stgmed, 0);
        return true;
    }
} 
//@----------------------------------------------------------------------------


///
/++
http://msdn.microsoft.com/ja-jp/library/system.windows.forms.dataformats%28v=vs.110%29.aspx
http://msdn.microsoft.com/en-us/library/windows/desktop/ff729168%28v=vs.85%29.aspx

static な定義済み Clipboard 形式名を提供します。 
これらを使用して IDataObject に格納するデータの形式を識別します。

++/
class DataFormats // docmain
{
	this()
	{
		outLog1("DataFormats:Start");
	}
	~this()
	{
		outLog1("DataFormats:end");
	}
	///
	static class Format // docmain
	{
		/// Data format ID number.
		final @property int id() // getter
		{
			return _id;
		}
		/// Data format name.
		final @property Dstring name() // getter
		{
			return _name;
		}
		package:
		int _id;
		Dstring _name;
		
		this()
		{
		}
	}
	
	static:
	
	/// Predefined data formats.
	@property Dstring bitmap() // getter
	{
		return getFormat(CF_BITMAP).name;
	}
	
	/+
	/// CSV Format (CSV: Comma-Separated Value) 
	@property Dstring commaSeparatedValue() // getter
	{
		return getFormat(?).name;
	}
	+/
	
	/// ditto
	@property Dstring dib() // getter
	{
		return getFormat(CF_DIB).name;
	}
	
	/// ditto
	@property Dstring dif() // getter
	{
		return getFormat(CF_DIF).name;
	}
	
	/// ditto
	@property Dstring enhandedMetaFile() // getter
	{
		return getFormat(CF_ENHMETAFILE).name;
	}
	
	/// ditto
	@property Dstring fileDrop() // getter
	{
		return getFormat(CF_HDROP).name;
	}
	
	/// ditto
	@property Dstring html() // getter
	{
		return getFormat("HTML Format").name;
	}
	
	/// ditto
	@property Dstring locale() // getter
	{
		return getFormat(CF_LOCALE).name;
	}
	
	/// ditto
	@property Dstring metafilePict() // getter
	{
		return getFormat(CF_METAFILEPICT).name;
	}
	
	/// ditto
	@property Dstring oemText() // getter
	{
		return getFormat(CF_OEMTEXT).name;
	}
	
	/// ditto
	@property Dstring palette() // getter
	{
		return getFormat(CF_PALETTE).name;
	}
	
	/// ditto
	@property Dstring penData() // getter
	{
		return getFormat(CF_PENDATA).name;
	}
	
	/// ditto
	@property Dstring riff() // getter
	{
		return getFormat(CF_RIFF).name;
	}
	
	/// ditto
	@property Dstring rtf() // getter
	{
		return getFormat("Rich Text Format").name;
	}
	
	
	/+
	/// ditto
	@property Dstring serializable() // getter
	{
		return getFormat(?).name;
	}
	+/
	
	/// ditto
	@property Dstring stringFormat() // getter
	{
		return utf8; // ?
	}
	
	/// ditto
	@property Dstring utf8() // getter
	{
		return getFormat("UTF-8").name;
	}
	
	/// ditto
	@property Dstring symbolicLink() // getter
	{
		return getFormat(CF_SYLK).name;
	}
	
	/// ditto
	@property Dstring text() // getter
	{
		return getFormat(CF_TEXT).name;		// ansi text
	}
	
	/// ditto
	@property Dstring tiff() // getter
	{
		return getFormat(CF_TIFF).name;
	}
	
	/// ditto
	@property Dstring unicodeText() // getter
	{
		return getFormat(CF_UNICODETEXT).name;
	}
	
	/// ditto
	@property Dstring waveAudio() // getter
	{
		return getFormat(CF_WAVE).name;
	}
	
	// 拡張
	@property Dstring urlText() // getter
	{
		return 	"UniformResourceLocator";
	}
	@property Dstring UniformResourceLocator() // getter
	{
		return 	"UniformResourceLocator";
	}
	
	// Assumes _init() was already called and
	// -id- is not in -fmts-.
	private Format _didntFindId(int id)
	{
		Format result;
		result = new Format;
		result._id = id;
		result._name = getName(id);
		//synchronized // _init() would need to be synchronized with it.
		{
			fmts[id] = result;
		}
		return result;
	}
	
	
	///
	Format getFormat(int id)
	{
		_init();
		
		if(id in fmts)
			return fmts[id];
		
		return _didntFindId(id);
	}
	
	/// ditto
	// Creates the format name if it doesn't exist.
	Format getFormat(Dstring name)
	{
		outLog("DataFormats:getFormat: ", name);
		
		_init();
		foreach(Format onfmt; fmts)
		{
			if(!stringICmp(name, onfmt.name))
				return onfmt;
		}
		// Didn't find it.
		return _didntFindId(dfl.internal.utf.registerClipboardFormat(name));
	}
	
	/// ditto
	// Extra.
	Format getFormat(TypeInfo type)
	{
		return getFormatFromType(type);
	}
	
	
	private:
	Format[int] fmts; // Indexed by identifier. Must _init() before accessing!
	
	
	void _init()
	{
		if (fmts.length)
			return;
		
		void initfmt(int id, Dstring name)
		in
		{
			assert(!(id in fmts));
		}
		body
		{
			Format fmt;
			fmt = new Format;
			fmt._id = id;
			fmt._name = name;
			fmts[id] = fmt;
		}
		
		
		initfmt(CF_BITMAP, "Bitmap");
		initfmt(CF_DIB, "DeviceIndependentBitmap");
		initfmt(CF_DIF, "DataInterchangeFormat");
		initfmt(CF_ENHMETAFILE, "EnhancedMetafile");
		initfmt(CF_HDROP, "FileDrop");
		initfmt(CF_LOCALE, "Locale");
		initfmt(CF_METAFILEPICT, "MetaFilePict");
		initfmt(CF_OEMTEXT, "OEMText");
		initfmt(CF_PALETTE, "Palette");
		initfmt(CF_PENDATA, "PenData");
		initfmt(CF_RIFF, "RiffAudio");
		initfmt(CF_SYLK, "SymbolicLink");
		initfmt(CF_TEXT, "Text");
		initfmt(CF_TIFF, "TaggedImageFileFormat");
		initfmt(CF_UNICODETEXT, "UnicodeText");
		initfmt(CF_WAVE, "WaveAudio");
		
		fmts.rehash;
	}
	
	
	// Does not get the name of one of the predefined constant ones.
	Dstring getName(int id)
	{
		Dstring result;
		result = dfl.internal.utf.getClipboardFormatName(id);
		if (!result.length)
			throw new DflException("Unable to get format");
        
		outLog("DataFormats:getName: ", id, " ", result);

		return result;
	}
	
	
	package Format getFormatFromType(TypeInfo type)
	{
		outLog1("DataFormats:getFormatFromType");

		if(type == typeid(ubyte[]) || type == typeid(byte[]))
			throw new DflException("ubyte Unknown data format");
//			return getFormat(text);			// ansi text
		if(type == typeid(Dstring))
			return getFormat(text);			// ansi text
//			return getFormat(stringFormat);	// UTF-8 text
		if(type == typeid(Dwstring))
			return getFormat(unicodeText);	// UTF-16 text ?
		//if(type == typeid(Bitmap))
		//	return getFormat(bitmap);
		
		if(cast(TypeInfo_Class)type)
			throw new DflException("Unknown data format");
		
		return getFormat(getObjectString(type)); // ?
	}
	
}

