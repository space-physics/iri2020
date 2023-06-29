c iritec.for, version number can be found at the end of this comment.
c-----------------------------------------------------------------------        
C
C contains IRITEC, IONCORR subroutines to computed the 
C total ionospheric electron content (TEC)
C
c-----------------------------------------------------------------------        
C Corrections
C
C  3/25/96 jmag in IRIT13 as input
C  8/31/97 hu=hr(i+1) i=6 out of bounds condition corrected
C  9/16/98 JF(17) added to input parameters; OUTF(11,50->100)
C  ?/ ?/99 Ne(h) restricted to values smaller than NmF2 for topside        
C 11/15/99 JF(20) instead of JF(17)
C 10/16/00 if hr(i) gt hend then hr(i)=hend
C 12/14/00 jf(30),outf(20,100),oarr(50)
C
C Version-mm/dd/yy-Description (person reporting correction)
C 2000.01 05/07/01 current version
c 2000.02 10/28/02 replace TAB/6 blanks, enforce 72/line (D. Simpson)
c 2000.03 11/08/02 common block1 in iri_tec with F1reg
c 2007.00 05/18/07 Release of IRI-2007
c 2007.02 10/31/08 outf(.,100) -> outf(.,500)
c
C 2012.00 10/05/11 IRI-2012: bottomside B0 B1 model (SHAMDB0D, SHAB1D),
C 2012.00 10/05/11    bottomside Ni model (iriflip.for), auroral foE
C 2012.00 10/05/11    storm model (storme_ap), Te with PF10.7 (elteik),
C 2012.00 10/05/11    oval kp model (auroral_boundary), IGRF-11(igrf.for), 
C 2012.00 10/05/11    NRLMSIS00 (cira.for), CGM coordinates, F10.7 daily
C 2012.00 10/05/11    81-day 365-day indices (apf107.dat), ap->kp (ckp),
C 2012.00 10/05/11    array size change jf(50) outf(20,1000), oarr(100).
C
C 2020.00 03/15/23 Inclusion of plasmasphere 
C 2020.00 03/15/23 Revised numerical integration and stepsizes
C 2020.01 03/23/23 Revised IRIT13 to IRITEC, deleted iri_tec
C 2020.02 05/10/23 Added JFF(50) 
C
c-----------------------------------------------------------------------        
C
C
        subroutine IRITEC(ALATI,ALONG,jmag,jf,iy,md,hour,hbeg,hend,
     &                          hstep,oarr,tecbo,tecto)
c-----------------------------------------------------------------------        
c Program for numerical integration of IRI profiles from h=hbeg
C to h=hend. 
C       
C  INPUT:  ALATI,ALONG  LATITUDE NORTH AND LONGITUDE EAST IN DEGREES
C          jmag         =0 geographic   =1 geomagnetic coordinates
C          jf(1:50)     =.true./.false. flags; explained in IRISUB.FOR
C          iy,md        date as yyyy and mmdd (or -ddd)
C          hour         decimal hours LT (or UT+25)
c          hbeg,hend    upper and lower integration limits in km
c          hstep        stepsize in km
C 
C  OUTPUT: tecbo,tecto  Total Electron Content in m-2 below hmF2 (tecb)
C                       and above hmF2 (tect)
c-----------------------------------------------------------------------        

        dimension       outf(20,1000),oarr(100)
        logical         jf(50),jff(50)

c
c turning off computations that are not needed for integration
c

          do 2938 i=1,50
2938         jff(i) = jf(i)
          jff(2)=.false.       ! f=no temperatures (t)
          jff(3)=.false.       ! f=no ion composition (t)
          jff(21)=.false.      ! t=ion drift computed f=not comp.(f)
          jff(28)=.false.	  ! t=spread-F computed f=not comp. (f)
          jff(33)=.false. 	  ! t=auroral boundary   f=off (f)
          jff(34)=.false. 	  ! t=messages on f= off (t)
          jff(35)=.false. 	  ! t=auroral E-storm model on f=off (f)
          jff(47)=.false. 	  ! t=CGM on  f=CGM off (f)
		
        iisect = int(((hend-hbeg)/hstep)/1000.0)
		if(iisect.lt.1) goto 2345
		hsect = 1000.0 * hstep
		hastep = hstep/2.0
        tect= 0.
        tecb= 0.
c
c calculate IRI densities from hbeg+hstep/2 to hend-hstep/2 
c		
		do j=1,iisect
           abeg = hbeg + (j-1)* hsect + hastep
           aend = abeg + hsect - hstep
           call IRI_SUB(JFF,JMAG,ALATI,ALONG,IY,MD,HOUR,
     &          abeg,aend,hstep,OUTF,OARR)
	       if(j.lt.2) then
		      hmF2=oarr(2)
		      xnmF2=oarr(1)
              xnorm = xnmF2/1000.
			  endif
c
c Numerical integration for each 1000 point segment.
c (xnorm is divided by 1000 to account for heights in km)
c
		   hx = abeg + hastep 
		   do jj=1,1000
		      yyy = outf(1,jj) * hstep / xnorm
			  if (hx.le.hmF2) then
                tecb = tecb + yyy
              else
                tect = tect + yyy
		      endif
			  hx = hx + hstep
              enddo
		   enddo
c
c numerical integration for the last segment
c
2345    hlastbeg = hbeg + iisect * hsect
        ilast = int((hend-hlastbeg)/hstep)
           abeg = hlastbeg + hastep
           aend = hlastbeg + ilast * hstep - hastep
           call IRI_SUB(JF,JMAG,ALATI,ALONG,IY,MD,HOUR,
     &          abeg,aend,hstep,OUTF,OARR)
		   hx = abeg + hastep 
		   do jj=1,ilast
		     yyy = outf(1,jj) * hstep / xnorm
			 if (hx.le.hmF2) then
                tecb = tecb + yyy
             else
                tect = tect + yyy
		     endif
			 hx = hx + hstep 
             enddo
		   
        tecto = tect * xnmF2
        tecbo = tecb * xnmF2

        return
        end
c
c
        real function ioncorr(tec,f)
c-----------------------------------------------------------------------        
c computes ionospheric correction IONCORR (in m) for given vertical
c ionospheric electron content TEC (in m-2) and frequency f (in Hz)
c-----------------------------------------------------------------------        
        ioncorr = 40.3 * tec / (f*f)
        return
        end
c
c
        subroutine iri_tec (jf,hstart,hend,istep,tectot,tectop,tecbot)
c-----------------------------------------------------------------------        
C subroutine to compute the total ionospheric content
C INPUT:      
C   hstart  altitude (in km) where integration should start
C   hend    altitude (in km) where integration should end
C   istep   =0 [fast, but higher uncertainty <5%]
C           =1 [standard, recommended]
C           =2 [stepsize of 1 km; best TEC, longest CPU time]
C OUTPUT:
C   tectot  total ionospheric content in tec-units (10^16 m^-2)
C   tectop  topside content (in %)
C   tecbot  bottomside content (in %)
C
C The boundaries for regions with different stepsizes are:
C   h1=haa lower boundary of IRI
c   h2=hmF2-50km
c   h3=hmF2+50km 
c   h4=2,000km upper boundary of standard IRI 
c   h5=hpp plasmapause height, 
c   h6=30,000km upper boundary for IRI with plasmaspheric
c      extension
C The stepsizes are
c   istep   below h1   h1-h2  h2-h3   h3-h4   h4-h5   h5-h6
C     0      1.0km    10.0km  5.0km  100km   1000km  2000km
C     1      1.0km     5.0km  2.0km   50km    500km  1000km
C     2      1.0km     1.0km  1.0km  1.0km    100km   500km   
C
c-----------------------------------------------------------------------        

        dimension       step(6),hr(6)
        logical     	jf(50)

c turning off computations that are not needed for integration

          jf(2)=.false.       ! f=no temperatures (t)
          jf(3)=.false.       ! f=no ion composition (t)
          jf(21)=.false.      ! t=ion drift computed f=not comp.(f)
          jf(28)=.false.	  ! t=spread-F computed f=not comp. (f)
          jf(33)=.false. 	  ! t=auroral boundary   f=off (f)
          jf(34)=.false. 	  ! t=messages on f= off (t)
          jf(35)=.false. 	  ! t=auroral E-storm model on f=off (f)
          jf(47)=.false. 	  ! t=CGM on  f=CGM off (f)

        iisect = int((hend-hstart)/1000.0)+1
		
        sumtop = 0.0
        sumbot = 0.0
		
        do 2167 j=1,iisect
        call IRI_SUB(JF,JMAG,ALATI,ALONG,IY,MD,HOUR,
     &          abeg,aend,astp,OUTF,OARR)
		
2167		enddo
C
C find the starting and end point for the integration
C        
        ia=1
		ie=1
        do 2918 i=1,5 
		    if (hstart.ge.hr(i)) ia=i+1
2918        if (hend.gt.hr(i)) ie=i

C
C start the numerical integration
C

        h = hstart
        ir=ia
		if(ia.eq.1) then
			h=hr(1)
            ir=2
			endif
1       hu = hr(ir)
		delx = step(ir)
        h = h + delx
        if (h.le.hu) then
		  hx = h - delx/2.0
          yne = XE_1(hx)
          yyy = yne * delx/xnorm
		  htop = h
		else
		  hdo = h - delx
		  dhdo = hu - hdo
		  hx = hu - dhdo/2.0
          yne = XE_1(hx)
          yyy = yne * dhdo/xnorm
		  ir=ir+1
		  htop=hu
		  h=hu
		endif
        if (htop.le.hmf2) then
                sumbot = sumbot + yyy
        else
                sumtop = sumtop + yyy
		endif
		if(ir.le.ie) goto 1
C
C Add the last contribution
C		
        hu=hr(ie)
		delx = step(ie)
111     h = h + delx
        if (h.le.hend) then
		  hx = h - delx/2.0
          yne = XE_1(hx)
          yyy = yne * delx/xnorm
		  htop=h
		else
		  hdo = h - delx
		  dhdo = hend - hdo
		  hx = hend - dhdo/2.0
          yne = XE_1(hx)
          yyy = yne * dhdo/xnorm
		  htop=hend
		endif
        if (htop.le.hmf2) then
                sumbot = sumbot + yyy
        else
                sumtop = sumtop + yyy
		endif
		if(htop.lt.hend) goto 111

        zzz = sumtop + sumbot
        tectop = sumtop / zzz * 100.
        tecbot = sumbot / zzz * 100.
        tectot = zzz * xnmf2    

      RETURN
      END