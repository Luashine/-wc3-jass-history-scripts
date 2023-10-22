# Jass History Scripts

This is a repo for the utilities required to make a diff of historic Jass other scripts files between old versions.

## MPQ Extraction

**Q:** *WTF is this?*

**A:** I'm glad you asked, may I correct your question? "Why the fuck did I need to do this?" It's much simpler to answer now, that is because the [stormlib](https://github.com/ladislav-zezula/StormLib) by Ladik is a clusterfuck.

Don't get me wrong, it's great it exists and is open source. However what's not so great is its attempted simple API, if we are to trust
[the comment](https://github.com/ladislav-zezula/StormLib/commit/3a926f0228c68d7d91cf3946624d7859976440ec#diff-d0a5ce336620fdb95c78115f8952999277e761790910658313f7b93fb28adc5b),
since April 11th, 2003, is in the state of `SetLastError(ERROR_CALL_NOT_IMPLEMENTED);`.

Anyway, it has [another API](https://github.com/ladislav-zezula/StormLib/blob/bf6a10b5e54c541ba5b17562ab139e58eac6393c/src/StormLib.h#L990) but I don't see how it's possible to extract files without a known path given these functions. That is in case a listfile is missing/deleted, MPQEditor by Ladik still lists all files as laid out by the file map of the MPQ. Yes, it does so without names, but these files remain extractable. That's important to me and I don't see a way (other than understanding the entire code base) to accomplish this.

So that is why I didn't make a CLI tool based on stormlib. At the same time stormlib is the most advanced MPQ reader out there and Ladik should be worshipped for unbreaking various MPQ corruption attempts to make them readable. And he has been doing this for 2 decades. Did you donate?

Maybe I should've done a CLI tool based on another MPQ library, I don't know, it's happened now. I macro'ed MPQEditor to do what I want instead. Ok this seems stupid in retrospect. It works though. May I ask you now to drink a glass of water, it's important to drink enough water throughout the day!

### extract-from-mpq.sh

Written to be used on Windows under Cygwin.

Extracts tar archives, controls the folder structure, orchestrates the macro and repeats this process for every .tar in the list. The paths are hardcoded. Also prepares the MPQEditor launch by setting "read-only" and extraction path directly in its config.

The tar archives are expected to have this structure:

```
./Warcraft III/   # the folder can have any name, autodetection
./Warcraft III/war3.mpq
# etc
```

Game versions ROC Beta, ROC, TFT Beta, TFT with MPQ game data are supported. CASC was introduced in 1.30, use CASCViewer there.

### mpqeditor-gui-extract-macro.au3

Windows-only, for build instructions see [WC3 Code Paste Helper](https://github.com/Luashine/wc3-debug-console-paste-helper), it's written in AutoIt.

A really robust macro to wait for MPQEditor to open, searches the TreeView for the hardcoded elements (see `MPQ_isFilterMatch`) and extracts them. Once finished, exits with code 0. This way the extract script knows it all went fine. Uses no keyboard / map button sending, all you need to do is to press "OK" in the open window, verifying the options of opening.

### Execution flow

1. Run `extract-from-mpq.sh`
2. Creates extraction directories
3. Extracts .tar archive in extraction temp folder
4. Sets up MPQEditor config
5. Launches MPQEditor, passes MPQ files to it
5. Launch Au3 macro
6. Wait for macro to extract the files and exit
7. You check the Open settings, you click OK to open
8. Macro runs and extracts the hardcoded items
9. Macro exits
10. Script closes MPQEditor
11. Go to 2, for the next game archive in list
