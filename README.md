WeirdEd - a mod for DromEd
==========================

This mod uses squirrel scripts to do stuff in edit mode in NewDark DromEd.

Installing the mod
------------------

1. Put the WeirdEd folder in a suitable location, and add it to your `mod_path` in `cam_mod.ini`.
2. Edit `menus.cfg` to add the WeirdEd menu, following the instructions in `WeirdEd/editor/weirded_menu.cfg`.
3. Edit `Default.bnd` to add the WeirdEd keybinds, following the instructions in `WeirdEd/editor/weirded_default.bnd`.

Set up your mission to use WeirdEd
----------------------------------

The first time you want to use any WeirdEd scripts in a mission, you need to:

1. Ensure squirrel.osm is loaded, with `script_load squirrel`.
2. Ensure the 'Ed' and 'EdCursor' objects exist, by using **File**->**Load DbMod**, and selecting `WeirdEd/editor/Ed.dml`.

Set up your gamesys to use Cables
---------------------------------

The first time you want to use Cables in a mission/campaign, you need to:

1. Ensure the 'Cable' archetype exists in the gamesys, by using File->Load DbMod, and selecting `WeirdEd/editor/Cable.dml`.
2. Ensure the cable models are installed: copy the models and textures from `WeirdEd/fm_assets/obj/` into your FM's `obj/` folder.

Using Cables
------------

To create a cable:

1. Move the pink 'EdCursor' object to where the cable should start.
2. Choose **WeirdEd**->**Cable**->**Start cable**. This will place the red 'EdMarker1' at the cursor position.
3. Move 'EdCursor' to where the other end of this cable segment should go.
4. Press **G** (or choose **WeirdEd**->**Cable**->**Make cable segment**). This will create the cable segment, leaving the orange 'EdMarker2' where it started, and moving the red 'EdMarker1' to the cursor position ready for the next segment.
5. Repeat steps 3 and 4 to place more cable segments.
6. When you have placed the whole cable, press **Ctrl+G** (or choose **WeirdEd**->**Cable**->**Finish cable**) to finish and clean up the markers.

Each cable segment will be created with the currently selected cable width (default is 1). If you want to use a different thickness of cable, use **WeirdEd**->**Cable**->**Set Width ...** before creating a segment.

If, just after creating a cable segment you realise it is in the wrong place or is the wrong width, you can correct it. If you need to change its start point, move the pink cursor; if you need to change its endpoint, move the orange 'EdMarker2'; if you need to change its width, use the **Set Width ...** menu again. Then, press **Shift+G** (or choose **WeirdEd**->**Cable**->**Redo last**) to update the last placed segment.
