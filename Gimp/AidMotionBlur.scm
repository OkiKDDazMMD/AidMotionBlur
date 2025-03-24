(define (script-fu-aid-motionblur
          image drawables bOpacity bGauss fSizeX fSizeY)
     (let* 
          (
               (vector_layers_ID (car (gimp-image-get-layers image)))
               (num_layers (vector-length vector_layers_ID))
               (check_group 0)
               (horizontalRadius (* 0.32 fSizeX))
               (verticalRadius (* 0.32 fSizeY))
               (newOpacity (/ 100.0 num_layers))
               (newGroupLayer 0)
               (newLayer 0)
               (newFloating 0)
          )

          (while (and (> num_layers 0) (< check_group 1) )
               (if (= (car(gimp-item-is-group (vector-ref vector_layers_ID (- num_layers 1)))) 1)
                    (set! check_group (+ check_group 1))
               )
               (set! num_layers (- num_layers 1))
          )

          (if (> check_group 0)
               (begin
                    (gimp-message "Delete LayerGroup")
               )
               (begin
                    (gimp-message (string-append "Opacity: " (number->string bOpacity) " Gauss: " (number->string bGauss)))
                    (set! num_layers (vector-length vector_layers_ID))
                    (gimp-context-push)
                    (gimp-context-set-feather FALSE)
                    (gimp-image-undo-group-start image)

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
                              (gimp-drawable-merge-new-filter (vector-ref vector_layers_ID (- num_layers 1)) "gegl:gaussian-blur" 0 LAYER-MODE-NORMAL 1.0 "std-dev-x" horizontalRadius "std-dev-y" verticalRadius "filter" "auto")
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

                    (gimp-image-undo-group-end image)
                    (gimp-displays-flush)
                    (gimp-context-pop)
                    (gimp-message "Completed")
               )
          )
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
                           SF-TOGGLE "処理は全レイヤーの不透明度変更までに" FALSE
                           SF-TOGGLE "ガウスぼかし" FALSE
                           SF-ADJUSTMENT "Size X" '(10.0 0.1 1000 1 10 1 0)
                           SF-ADJUSTMENT "Size Y" '(10.0 0.1 1000 1 10 1 0)
 )

(script-fu-menu-register "script-fu-aid-motionblur" "<Image>/Script-Fu")
