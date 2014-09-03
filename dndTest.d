/++++
Drag And Drop Test.d
漢字　表示　テスト
++++/
import dfl.all;
import std.file;

enum WindowClientWidth  = 400;
enum WindowClientHeight = 300;

class MainForm: Form
{
	GroupBox myGroup;
	RadioButton ansiDnd, unicodeDnd, fileDnd, textDnd;
	Label label01, label02;
	int oFlag, selectFlag;
	string dndText;
	
	this()
    {
        clientSize = dfl.drawing.Size(WindowClientWidth, WindowClientHeight);
        startPosition = FormStartPosition.CENTER_SCREEN;
        
        text = "Drag and Drop TEST";
        dndText = "Drag and Drop TEST";
        oFlag = 0;
		selectFlag = 0;
        
        // Add a GroupBox.
        with(myGroup = new GroupBox)
        {
            bounds = Rect(4, 4, this.clientSize.width - 8, 90); // Set the x, y, width, and height.
            text = "Select Drag and Drop type";
            parent = this; // Set myGroup's parent to this Form.
        }
        with(ansiDnd = new RadioButton)
        {
            bounds = Rect(6, 18, 160, 13);
            text = "CF_TEXT";
            checked = true;
            click ~= &ansiBtn_click;
            parent = myGroup;
        }
        
        with(unicodeDnd = new RadioButton)
        {
            bounds = Rect(6, ansiDnd.bottom + 5, 160, 13); // 4px below ansiDnd.
            text = "CF_UNICODE";
            click ~= &unicodeBtn_click;
            parent = myGroup;
        }
        
        with(fileDnd = new RadioButton)
        {
            bounds = Rect(6, unicodeDnd.bottom + 5, 160, 13);
            text = "CF_HDROP";
            click ~= &fileBtn_click;
            parent = myGroup;
        }
        with(textDnd = new RadioButton)
        {
            bounds = Rect(6, fileDnd.bottom + 5, 160, 13);
            text = "text";
            click ~= &textBtn_click;
            parent = myGroup;
        }
		
        with (label01 = new Label) {
            label01.text = "Label01:\r\nDrugs in this window";
            top  = myGroup.bottom + 4;
            left = 4;
            width = this.clientSize.width - 8;
            height = 60;
            useMnemonic = false;
            borderStyle = BorderStyle.FIXED_3D;
            
            //IDropSource
            mouseDown 			~= &label_mouseDown;
            queryContinueDrag	~= &label_queryContinueDrag;
            // giveFeedback		~= &label_GiveFeedback;
            parent = this;
        }
        with (label02 = new Label) {
            label02.text = "Label02:\r\n↓Drop here↓";
            top  = label01.bottom + 4;
            left = 4;
            width = this.clientSize.width - 8;
            height = 140;
            borderStyle = BorderStyle.FIXED_3D;
            allowDrop = true;
            
            //IDropTarget
            dragEnter	~= &label02_dragEnter;
            // dragLeave 	
            dragOver	~= &label02_dragOver;
            dragDrop	~= &label02_dragDrop;
            parent = this;
        }
/++
        wstring ws = text.UTF8toUTF16();
        outLog("dump ws");
        outdumpLog(cast(void*)ws, ws.length * 2);
        string ss = ws.UTF16toUTF8();
        outLog("dump ss");
        outdumpLog(cast(void*)ss, ss.length);
++/
    }
    private void ansiBtn_click(Object sender, EventArgs ea)
    {
        selectFlag = 0;
    }
    private void unicodeBtn_click(Object sender, EventArgs ea)
    {
        selectFlag = 1;
    }
    private void fileBtn_click(Object sender, EventArgs ea)
    {
        selectFlag = 2;
    }
    private void textBtn_click(Object sender, EventArgs ea)
    {
        selectFlag = 3;
    }
    
    string[] getFilePath(string path)
    {
        bool extMatch(string path, string ext) {
            if (path[$ - ext.length .. $] == ext) {
                return true;
            }
            return false;
        }
        string[] files;
        foreach (DirEntry e; dirEntries(path, SpanMode.shallow)) {
            if (e.isFile() && extMatch(e.name, ".d")) {
                files ~= e.name;
            }
        }
        return files;
    }
    
    private void label_mouseDown(Object sender, MouseEventArgs ea)
    {
        if (oFlag == 0) {
            oFlag = 1;
            
            DragDropEffects result;
            auto data = new DataObject;
            
            switch (selectFlag) {
            case 0:
                data.setAnsiText(UTF8toANSI(dndText));
                break;
            case 1:
                data.setUnicodeText(UTF8toUTF16(dndText));
                break;
            case 2:
                data.setDropFile(getFilePath(getcwd()));
                break;
            case 3:
                data.setText(dndText);
                break;
            default:
                assert(0);
            }
            result = doDragDrop(data, DragDropEffects.COPY);
            
            oFlag = 0;
        }
    }
    private void label_queryContinueDrag(Object sender, QueryContinueDragEventArgs ea)
    {
        ea.action = DragAction.CONTINUE; // return S_OK;
    }
    // drag drop send
    private void label_GiveFeedback(Object sender, GiveFeedbackEventArgs ea)
    {
    }
//@----------------------------------------------------------------------------
	bool status;
    
    private void label02_dragEnter(Object sender, DragEventArgs ea)
    {
        outLog("label02_dragEnter");
        
        switch (selectFlag) {
        case 0:
            status = ea.data.queryAnsiText();
            break;
        case 1:
            status = ea.data.queryUnicodeText();
            break;
        case 2:
            status = ea.data.queryDropFile();
            break;
        case 3:
            status = ea.data.queryText();
            break;
        default:
            assert(0);
        }
        outLog("label02_dragEnter: status ", status ? "true" : "false");
        if (status)
            ea.effect = ea.allowedEffect & DragDropEffects.COPY;
        else
            ea.effect = DragDropEffects.NONE;
        
    }
    private void label02_dragOver(Object sender, DragEventArgs ea)
    {
        switch (selectFlag) {
        case 0:
            if (status && ea.data.queryAnsiText())
                ea.effect = ea.allowedEffect & DragDropEffects.COPY;
            
            break;
        case 1:
            if (status && ea.data.queryUnicodeText())
                ea.effect = ea.allowedEffect & DragDropEffects.COPY;
            
            break;
        case 2:
            if (status && ea.data.queryDropFile())
                ea.effect = ea.allowedEffect & DragDropEffects.COPY;
            
            break;
        case 3:
            if (status && ea.data.queryText())
                ea.effect = ea.allowedEffect & DragDropEffects.COPY;
            
            break;
        default:
            assert(0);
        }
    }
    private void label02_dragDrop(Object sender, DragEventArgs ea)
    {
        switch (selectFlag) {
        case 0:
            string s = ea.data.getAnsiText();
            // ANSI(MBCS/SJIS) to UTF8
            dndText = ANSItoUTF8(s);
            label02.text = dndText;
            break;
        case 1:
            wstring s = ea.data.getUnicodeText();
            // UTF16 to UTF8
            dndText = UTF16toUTF8(s);
            label02.text = dndText;
            break;
        case 2:
            string[] s = ea.data.getDropFile();
            dndText = "";
            foreach (v ; s) {
                dndText ~= v ~ "\r\n";
            }
            label02.text = dndText;
            break;
        case 3:
            dndText = ea.data.getText();
            label02.text = dndText;
            break;
        default:
            assert(0);
        }
    }
//@----------------------------------------------------------------------------
}


int main()
{
	int result = 0;
    
    try {
        // Application.autoCollect = false;
        setDebugLog(0);
        Application.run(new MainForm);
        outLog("----End");
    }
    catch(DflThrowable o) {
        msgBox(o.toString(), "Fatal Error", MsgBoxButtons.OK, MsgBoxIcon.ERROR);
        result = 1;
    }
    return result;
}

