#!/usr/bin/python
# -*- coding: utf-8 -*-

from gimpfu import *

def plugin_main(image, layer, bOpacity, bGauss, fSizeX, fSizeY):
    numlayers = len(image.layers)
    newOpacity = 100.0/numlayers

    image.undo_group_start()

    for layer in image.layers:
        layer.opacity = newOpacity
        layer.mode = 28
        if bGauss:
            pdb.plug_in_gauss_iir2(image, layer, fSizeX, fSizeY)

    # レイヤーグループを作成
    layer_group = pdb.gimp_layer_group_new(image)
    layer_group.name = "Layer Group"
    
    # レイヤーグループを画像に追加
    pdb.gimp_image_insert_layer(image, layer_group, None, 0)

    for layer in image.layers:
        if layer != layer_group:
            pdb.gimp_image_reorder_item(image, layer, layer_group, 0)

    if not bOpacity:
        for layer in layer_group.layers:
            # pdb.gimp_message("レイヤー探索開始")
            if not pdb.gimp_layer_get_mask(layer):
                # pdb.gimp_message("レイヤー発見")
                # レイヤーマスクを作成
                mask = pdb.gimp_layer_create_mask(layer, ADD_ALPHA_TRANSFER_MASK)
    
                # レイヤーにマスクを追加
                pdb.gimp_layer_add_mask(layer, mask)
    
                # マスク編集モードを有効にする
                pdb.gimp_layer_set_edit_mask(layer, TRUE)

                # ソースレイヤーのマスクをコピー
                source_mask = pdb.gimp_layer_get_mask(layer)
                pdb.gimp_edit_copy(source_mask)
                # pdb.gimp_message("ソースレイヤーのマスクをコピー終了")

                # 新しいレイヤーを作成
                new_layer = pdb.gimp_layer_new(image, image.width, image.height, RGBA_IMAGE, "Mask Copy", 100, NORMAL_MODE)
                pdb.gimp_image_insert_layer(image, new_layer, None, len(image.layers))
                # pdb.gimp_message("新しいレイヤーを作成")

                floating_sel = pdb.gimp_edit_paste(new_layer, True)
                pdb.gimp_floating_sel_anchor(floating_sel)

                pdb.gimp_item_set_visible(new_layer, False)
                # pdb.gimp_message("アルファマスクをコピーしたレイヤーを不可視に")

                merged_layer = pdb.gimp_image_merge_visible_layers(image, CLIP_TO_IMAGE)
                # レイヤーマスクを作成
                merged_mask = pdb.gimp_layer_create_mask(merged_layer, ADD_ALPHA_TRANSFER_MASK)

                # レイヤーにマスクを追加
                pdb.gimp_layer_add_mask(merged_layer, merged_mask)
    
                # マスク編集モードを有効にする
                pdb.gimp_layer_set_edit_mask(merged_layer, TRUE)

                # 選択を解除
                pdb.gimp_selection_none(image)

                break

    image.undo_group_end()

    gimp.displays_flush()


register(
        "motion_blur",                              #プロシージャの名前
        "AidMotionBlur",                               #プラグインの情報
        "MotionBlur",                               #詳しいプラグインの情報
        "OkiKD",                                    #プラグインの著者
        "OkiKD",                                    #コピーライト
        "2024/02/05",                               #日付
        "AidMotionBlur",                               #メニューに表示するプラグイン名
        "",                                         #画像タイプ
        [
         (PF_IMAGE, "image", "Input image", None),  # 画像
         (PF_LAYER, "layer", "Input layer", None),  # レイヤー (PF_DRAWABLE も可)
         (PF_BOOL, "bOpacity", "処理は全レイヤーの不透明度変更までに", False),
         (PF_BOOL, "bGauss", "ガウスぼかし", False),
         (PF_SPINNER, "fSizeX", "Size X", 10.0, (0.1, 1000, 1)),
         (PF_SPINNER, "fSizeY", "Size Y", 10.0, (0.1, 1000, 1)),
        ],                                          #引数
        [],                                         #戻り値
        plugin_main,                                # main 関数名
        menu="<Image>/test"                         #プラグインの登録場所
        )

main()
