(define (script-fu-aid-motionblur
          image drawables bHalved bOpacity bGauss fSizeX fSizeY)
     (let* 
          (
               (vector_layers_ID (car (gimp-image-get-layers image)))
               (num_layers (vector-length vector_layers_ID))
               (check_group 0)
               (horizontalRadius fSizeX)
               (verticalRadius fSizeY)
               (diffOpacity (/ 100.0 num_layers))
               (newOpacity (+ 100 diffOpacity))
               (newGroupLayer 0)
               (newLayer 0)
               (newFloating 0)
          )

          (gimp-image-undo-group-start image)
          (if (< num_layers 0)
               (begin
                    ; レイヤーが1枚だけの時は終了
                    (gimp-message "layers > 1")
               )
               (begin
                    (if (= bHalved TRUE)
                         (begin
                              (script-fu-reverse-layers image drawables)
                              (set! vector_layers_ID (car (gimp-image-get-layers image)))
                         )
                         (begin
                              (set! newOpacity diffOpacity)
                         )
                    )

                    ; ルートにレイヤーグループがないかチェック
                    (set! num_layers (vector-length vector_layers_ID))
                    (while (and (> num_layers 0) (< check_group 1) )
                         (if (= (car(gimp-item-is-group (vector-ref vector_layers_ID (- num_layers 1)))) 1)
                              (set! check_group (+ check_group 1))
                         )
                         (set! num_layers (- num_layers 1))
                    )

                    (if (> check_group 0)
                         (begin
                              ;  ルートにレイヤーグループがあったら終了
                              (gimp-message "Delete LayerGroup")
                         )
                         (begin
                              (set! num_layers (vector-length vector_layers_ID))
                              (gimp-context-push)
                              (gimp-context-set-feather FALSE)

                              (if (= bOpacity FALSE)
                                   (begin
                                        (set! newLayer (car(gimp-layer-create-mask (vector-ref vector_layers_ID 0) ADD-MASK-ALPHA-TRANSFER)))
                                        (gimp-layer-add-mask (vector-ref vector_layers_ID 0) newLayer)
                                        (gimp-edit-copy (vector newLayer))
                                        (set! newLayer (car (gimp-layer-new image "MaskCopy"
                                                                      (car (gimp-image-get-width image))
                                                                      (car (gimp-image-get-height image))
                                                                      RGB-IMAGE 100 LAYER-MODE-NORMAL)
                                                       )
                                        )
                                        (gimp-image-insert-layer image newLayer 0)
                                        (gimp-edit-paste newLayer)
                                        (set! newFloating (car (gimp-image-get-floating-sel image)))
                                        (gimp-floating-sel-anchor newFloating)
                                        (gimp-item-set-visible newLayer FALSE)
                                   )
                              )

                              (set! newGroupLayer (car (gimp-group-layer-new image "LayerGroup")))
                              (gimp-image-insert-layer image newGroupLayer)

                              (while (> num_layers 0)
                                   (if (= bGauss TRUE)
                                        (gimp-drawable-append-new-filter (vector-ref vector_layers_ID (- num_layers 1)) "gegl:gaussian-blur" 0 LAYER-MODE-REPLACE 1.0 "std-dev-x" horizontalRadius "std-dev-y" verticalRadius "filter" "auto")
                                   )

                                   (if (= bHalved TRUE)
                                        (begin
                                             (set! newOpacity (- newOpacity diffOpacity))
                                        )
                                   )
                                   (gimp-layer-set-opacity (vector-ref vector_layers_ID (- num_layers 1)) newOpacity)
                                   (gimp-image-reorder-item image (vector-ref vector_layers_ID (- num_layers 1)) newGroupLayer)
                                   (set! num_layers (- num_layers 1))
                              )

                              (if (= bOpacity FALSE)
                                   (begin
                                        (set! newLayer (car (gimp-group-layer-merge newGroupLayer)))
                                        (set! newFloating (car(gimp-layer-create-mask newLayer ADD-MASK-ALPHA-TRANSFER)))
                                        (gimp-layer-add-mask newLayer newFloating)
                                   )
                              )

                              (gimp-displays-flush)
                              (gimp-context-pop)
                              (gimp-message "Completed")
                         )
                    )
               )
          )
          (gimp-image-undo-group-end image)
     )
)

(script-fu-register-filter "script-fu-aid-motionblur"                     ;function name
                           "Aid MotionBlur"                              ;menu label
                           "Creates a MotionBlur from multiple images"  ;description
                           "Oki_KD"                                      ;author
                           "Oki_KD"                                      ;copyright notice
                           "2025/03/19"                                  ;date created
                           "*"                                            ;image
                           SF-ONE-DRAWABLE                               ;drawables
                           SF-TOGGLE "不透明度減衰" FALSE
                           SF-TOGGLE "処理は全レイヤーの不透明度変更までに" FALSE
                           SF-TOGGLE "ガウスぼかし" FALSE
                           SF-ADJUSTMENT "Size X" '(1.5 0.01 1000 1 10 2 0)
                           SF-ADJUSTMENT "Size Y" '(1.5 0.01 1000 1 10 2 0)
 )

(script-fu-menu-register "script-fu-aid-motionblur" "<Image>/Script-Fu")
