; docformat = 'rst'
; geo2polsar_run.pro
;    This program is free software; you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation; either version 2 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.

PRO geo2polsar_run_define_buttons, buttonInfo
  ENVI_DEFINE_MENU_BUTTON, buttonInfo, $
    VALUE = 'Construct ENVI Covariance Matrix Image', $
    REF_VALUE = 'AIRSAR Scattering Classification', $
    EVENT_PRO = 'geo2polsar_run', $
    UVALUE = 'GEO',$
    POSITION = 'after'
END

;+
; :Description:
; utility to read georeferenced C2 (dual) and C3 (quad) polarimetric 
; covariance matrix files generated by polSARpro and MapReady 
; software from SLC polarimetric TerraSAR-X or 
; Radarsat-2 images and convert to a single 6-band complex image 
; Unused bands for partial polarization are zeros
; :Params:
;      event:  in, required
;         if called from the ENVI Classic menu
; :KEYWORDS:
;    NONE
; :Uses:
;    ENVI
; :Author:
;       Mort Canty (2013)
;-    
pro geo2polSAR_run, event
; utility to read georeferenced 2x2 scattering matrix files generated
; by Gamma (or MapReady) software from polarimetric TerraSAR-X or 
; Radarsat-2 images and convert to 6-band complex image 
; (covariance matrix format)
; Unused bands for partial polarization are zeros
; Mort Cantry (2013)

   COMPILE_OPT IDL2
   
   envi_select, title='Choose (spatial subset of) C11 image', $
                fid=fid, dims=dims, pos=pos, /band_only
   if (fid eq -1) then begin       
         print, 'cancelled'
         return
      end     
   envi_file_query, fid, fname=fname
   cols = dims[2]-dims[1]+1
   rows = dims[4]-dims[3]+1
; map tie point
   map_info = envi_get_map_info(fid=fid)
   envi_convert_file_coordinates, fid, $
      dims[1], dims[3], e, n, /to_map
   map_info.mc = [0D,0D,e,n]   
; output image (complex, bsq)
   outim = complexarr(cols,rows,6)
   outim[*,*,0] = envi_get_data(fid=fid,dims=dims,pos=pos)
   bandnames = ['C11','C12','C13','C22','C23','C33']
   envi_select, title='Choose (spatial subset of) real part of C12 image or press cancel', $
                fid=fid, pos=pos, /band_only
   if (fid ne -1) then begin 
     real_part = envi_get_data(fid=fid,dims=dims,pos=pos)
     envi_select, title='Choose (spatial subset of) imaginary part of C12 image', $
                fid=fid, pos=pos, /band_only
     imaginary_part = envi_get_data(fid=fid,dims=dims,pos=pos)
     outim[*,*,1] = complex(real_part,imaginary_part)
   end else bandnames[1] = '-'     
   envi_select, title='Choose (spatial subset of) real part of C13 image or press cancel', $
                fid=fid, pos=pos, /band_only
   if (fid ne -1) then begin 
     real_part = envi_get_data(fid=fid,dims=dims,pos=pos)
     envi_select, title='Choose (spatial subset of) imaginary part of C13 image', $
                fid=fid, pos=pos, /band_only
     imaginary_part = envi_get_data(fid=fid,dims=dims,pos=pos)
     outim[*,*,2] = complex(real_part,imaginary_part)
   end else bandnames[2] = '-'               
   envi_select, title='Choose (spatial subset of) C22 image or press cancel', $
                fid=fid, pos=pos, /band_only
   if (fid ne -1) then outim[*,*,3] = envi_get_data(fid=fid,dims=dims,pos=pos)   $
      else bandnames[3] = '-'   
   envi_select, title='Choose (spatial subset of) real part of C23 image or press cancel', $
                fid=fid, pos=pos, /band_only
   if (fid ne -1) then begin 
     real_part = envi_get_data(fid=fid,dims=dims,pos=pos)
     envi_select, title='Choose (spatial subset of) imaginary part of C23 image', $
                fid=fid, pos=pos, /band_only
     imaginary_part = envi_get_data(fid=fid,dims=dims,pos=pos)
     outim[*,*,4] = complex(real_part,imaginary_part)
   end else bandnames[4] = '-'                       
   envi_select, title='Choose (spatial subset of) C33 image or press cancel', $
             fid=fid, pos=pos, /band_only
   if (fid ne -1) then outim[*,*,5] = envi_get_data(fid=fid,dims=dims,pos=pos)  $ 
       else bandnames[5] = '-'    
    base = widget_auto_base(title='Output file')
    sb = widget_base(base, /row, /frame)
    wp = widget_outf(sb, uvalue='outf', /auto)
    result = auto_wid_mng(base)
    if (result.accept eq 0) then $
       envi_enter_data, outim, map_info = map_info, bnames = bandnames $
    else begin
       openw, lun, result.outf, /get_lun    
       writeu, lun, outim
       free_lun, lun
       envi_setup_head,fname=result.outf, ns=cols, $
                   nl=rows, nb=6, $
                   data_type=6, $
                   file_type=0, $
                   interleave = 0, /write, $
                   map_info=map_info,$
                   bnames=bandnames
    endelse                
end

