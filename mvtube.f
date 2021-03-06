c-----------------------------------------------------------------------
c  nek5000 user-file template
c
c  user specified routines:
c     - uservp  : variable properties
c     - userf   : local acceleration term for fluid
c     - userq   : local source term for scalars
c     - userbc  : boundary conditions
c     - useric  : initial conditions
c     - userchk : general purpose routine for checking errors etc.
c     - userqtl : thermal divergence for lowMach number flows
c     - usrdat  : modify element vertices
c     - usrdat2 : modify mesh coordinates
c     - usrdat3 : general purpose routine for initialization
c
c-----------------------------------------------------------------------
      subroutine uservp(ix,iy,iz,eg) ! set variable properties

c      implicit none

      integer ix,iy,iz,eg

      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'

      integer e
c     e = gllel(eg)

      udiff  = 0.0
      utrans = 0.0

      return
      end
c-----------------------------------------------------------------------
      subroutine userf(ix,iy,iz,eg) ! set acceleration term
c
c     Note: this is an acceleration term, NOT a force!
c     Thus, ffx will subsequently be multiplied by rho(x,t).
c
c      implicit none

      integer ix,iy,iz,eg

      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'

      integer e
c     e = gllel(eg)

      ffx = 0.0
      ffy = 0.0
      ffz = 0.0

      return
      end
c-----------------------------------------------------------------------
      subroutine userq(ix,iy,iz,eg) ! set source term

c      implicit none

      integer ix,iy,iz,eg

      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'

      integer e
c     e = gllel(eg)

      qvol   = 0.0

      return
      end
c-----------------------------------------------------------------------
      subroutine userbc(ix,iy,iz,iside,eg) ! set up boundary conditions
c
c     NOTE ::: This subroutine MAY NOT be called by every process
c
c      implicit none

      integer ix,iy,iz,iside,eg

      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'
      integer e
      e = gllel(eg)

c      if (cbc(iside,gllel(eg),ifield).eq.'v01')

      ux   = 0.0
      uy   = 0.0
      uz   = 0.0
      temp = 0.0
C      if (cbc(iside,e,1).eq.'mv ') ux = 0.5/100.0


      return
      end
c-----------------------------------------------------------------------
      subroutine useric(ix,iy,iz,eg) ! set up initial conditions

c      implicit none

      integer ix,iy,iz,eg

      include 'SIZE'
      include 'TOTAL'
      include 'NEKUSE'

      ux   = 0.0
      uy   = 0.0
      uz   = 0.0
      temp = 0.0

      return
      end
c-----------------------------------------------------------------------
      subroutine userchk()

c      implicit none

      include 'SIZE'
      include 'TOTAL'

      if(istep.eq.0) call getmvv
      if(istep.eq.100) call getmvv
c      if(istep.eq.200) call getmvv
      call my_mv_mesh

      return
      end
c-----------------------------------------------------------------------
      subroutine userqtl ! Set thermal divergence

      call userqtl_scig

      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat()   ! This routine to modify element vertices

c      implicit none

      include 'SIZE'
      include 'TOTAL'

      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat2()  ! This routine to modify mesh coordinates

c      implicit none

      include 'SIZE'
      include 'TOTAL'
      integer iel,ifc,id_face
      common /usr_bound/ cbc_usr(6,lelt)
      character*3 cbc_usr

        do iel=1,nelv
        do ifc=1,2*ndim
          id_face = bc(5,ifc,iel,1)
          if (id_face.eq.1) then       ! SideSet 1
             cbc(ifc,iel,1) = 'W  '
             cbc_usr(ifc,iel) = 'W1 '
          elseif (id_face.eq.2) then   ! SideSet 2
             cbc(ifc,iel,1) = 'W  '
             cbc_usr(ifc,iel) = 'W1 '
          elseif (id_face.eq.3) then   ! SideSet 3
             cbc(ifc,iel,1) = 'W  '
             cbc_usr(ifc,iel) = 'W  '
          elseif (id_face.eq.4) then   ! SideSet 4 tube surface
             cbc(ifc,iel,1) = 'mv '
             cbc_usr(ifc,iel) = 'mv '
          endif
        enddo
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat3()

c      implicit none

      include 'SIZE'
      include 'TOTAL'

      return
      end
c----------------------------------------------------------------------
      subroutine mv2tube(x_in,y_in,z_in,mvx_out,mvy_out,mvz_out)
c      implicit none
      include 'SIZE'
      include 'TOTAL'

      real*8 x_in,y_in,z_in,r_in
      real*8 mvx_out,mvy_out,mvz_out
      real*8 dist_usr,mv_usr

      real*8 x_center,y_center,z_center
      real*8 radius
      real*8 nv(3)

      x_center = 0.0
      y_center = 0.0
      z_center = 0.0
      radius = 2.2

      r_in = sqrt((x_in-x_center)**2+(z_in-z_center)**2)

      nv(1) = (x_in-x_center)/r_in
cc      nv(2) = (y_in-y_center)/r_in
      nv(2) = 0.0
      nv(3) = (z_in-z_center)/r_in

      dist_usr = radius - r_in
      mv_usr = dist_usr/(dble(param(11))*dt)

      mvx_out = mv_usr*nv(1)
      mvy_out = mv_usr*nv(2)
      mvz_out = mv_usr*nv(3)

cc      if (nid.eq.0) write(6,*) "dist_usr: ",dist_usr

      return
      end

c----------------------------------------------------------------------
c----------------------------------------------------------------------
      subroutine getmvv
cc get moving velocity of moving surface.
      include 'SIZE'
      include 'TOTAL'
      common /usr_umesh/ umeshx(lx1,ly1,lz1,lelt),
     & umeshy(lx1,ly1,lz1,lelt),
     & umeshz(lx1,ly1,lz1,lelt)
      integer iel,ifc,id_face
      real*8 xx,yy,zz
      real*8 mvxx,mvyy,mvzz

      ntot = nx1*ny1*nz1*nelv

      call rzero(umeshx,ntot)
      call rzero(umeshy,ntot)
      call rzero(umeshz,ntot)

      facevx = 0.5/1000.0

      do iel=1,nelv
      do ifc=1,2*ndim
           id_face = bc(5,ifc,iel,1)
c           if (id_face.eq.1) then
c            do ix = 1,lx1*ly1*lz1
c             umeshx(ix,1,1,iel) = facevx
c            enddo
c           endif
           if (id_face.eq.4) then       ! SideSet 1 x-
            if(ifc.eq.1) then
c           Surface j=1
             j=1
             do i=1,lx1
             do k=1,lz1
                xx = xm1(i,j,k,iel)
                yy = ym1(i,j,k,iel)
                zz = zm1(i,j,k,iel)
                call mv2tube(xx,yy,zz,mvxx,mvyy,mvzz)
                umeshx(i,j,k,iel) = mvxx
                umeshy(i,j,k,iel) = mvyy
                umeshz(i,j,k,iel) = mvzz
             enddo
             enddo
            elseif (ifc.eq.2) then
c           Surface i=lx1
             i=lx1
             do j=1,ly1
             do k=1,lz1
                xx = xm1(i,j,k,iel)
                yy = ym1(i,j,k,iel)
                zz = zm1(i,j,k,iel)
                call mv2tube(xx,yy,zz,mvxx,mvyy,mvzz)
                umeshx(i,j,k,iel) = mvxx
                umeshy(i,j,k,iel) = mvyy
                umeshz(i,j,k,iel) = mvzz
              enddo
             enddo
            elseif (ifc.eq.3) then
c           Surface j=lx1
             j=lx1
             do i=1,lx1
             do k=1,lz1
                xx = xm1(i,j,k,iel)
                yy = ym1(i,j,k,iel)
                zz = zm1(i,j,k,iel)
                call mv2tube(xx,yy,zz,mvxx,mvyy,mvzz)
                umeshx(i,j,k,iel) = mvxx
                umeshy(i,j,k,iel) = mvyy
                umeshz(i,j,k,iel) = mvzz
             enddo
             enddo
              elseif (ifc.eq.4) then
c           Surface i=1
             i=1
             do j=1,lx1
             do k=1,lz1
                xx = xm1(i,j,k,iel)
                yy = ym1(i,j,k,iel)
                zz = zm1(i,j,k,iel)
                call mv2tube(xx,yy,zz,mvxx,mvyy,mvzz)
                umeshx(i,j,k,iel) = mvxx
                umeshy(i,j,k,iel) = mvyy
                umeshz(i,j,k,iel) = mvzz
             enddo
             enddo
            elseif (ifc.eq.5) then
c           Surface k=1
             k=1
             do i=1,lx1
             do j=1,lz1
                xx = xm1(i,j,k,iel)
                yy = ym1(i,j,k,iel)
                zz = zm1(i,j,k,iel)
                call mv2tube(xx,yy,zz,mvxx,mvyy,mvzz)
                umeshx(i,j,k,iel) = mvxx
                umeshy(i,j,k,iel) = mvyy
                umeshz(i,j,k,iel) = mvzz
             enddo
             enddo
            elseif (ifc.eq.6) then
c           Surface k=lx1
             k=lx1
             do i=1,lx1
             do j=1,lz1
                xx = xm1(i,j,k,iel)
                yy = ym1(i,j,k,iel)
                zz = zm1(i,j,k,iel)
                call mv2tube(xx,yy,zz,mvxx,mvyy,mvzz)
                umeshx(i,j,k,iel) = mvxx
                umeshy(i,j,k,iel) = mvyy
                umeshz(i,j,k,iel) = mvzz
             enddo
             enddo
            endif
            endif
        enddo
      enddo

      pmax=glmax(umeshx,ntot)
      pmin=glmin(umeshx,ntot)
      if (nid.eq.0) write(6,*) "umeshx: ",pmin," - ",pmax

      pmax=glmax(umeshy,ntot)
      pmin=glmin(umeshy,ntot)
      if (nid.eq.0) write(6,*) "umeshy: ",pmin," - ",pmax

      pmax=glmax(umeshz,ntot)
      pmin=glmin(umeshz,ntot)
      if (nid.eq.0) write(6,*) "umeshz: ",pmin," - ",pmax
      return
      end
c----------------------------------------------------------------------
      subroutine my_mv_mesh
      include 'SIZE'
      include 'TOTAL'
      common /usr_umesh/ umeshx(lx1,ly1,lz1,lelt),
     & umeshy(lx1,ly1,lz1,lelt),
     & umeshz(lx1,ly1,lz1,lelt)
      parameter (lt = lx1*ly1*lz1*lelt)
      common /mrthoi/ napprx(2),nappry(2),napprz(2)
      common /mrthov/ apprx(lt,0:mxprev)
     $              , appry(lt,0:mxprev)
     $              , apprz(lt,0:mxprev)
      common /mstuff/ d(lt),h1(lt),h2(lt),mask(lt)
      common /usr_bound/ cbc_usr(6,lelt)
      character*3 cbc_usr
      real mask,pmax,pmin
      real srfbl,volbl,delta,deltap1,deltap2,arg1,arg2
      real zero,one
      integer e,f
      integer icalld
      save    icalld
      data    icalld /0/

      n = nx1*ny1*nz1*nelv
      nface = 2*ndim

      if (icalld.eq.0) then
         icalld=1
         napprx(1)=0
         nappry(1)=0
         napprz(1)=0
         nxz   = nx1*nz1
         nxyz  = nx1*ny1*nz1
         srfbl = 0.   ! Surface area of elements in b.l.
         volbl = 0.   ! Volume of elements in boundary layer
         do e=1,nelv
         do f=1,nface
            if (cbc_usr(f,e).eq.'mv ') then
               srfbl = srfbl + vlsum(area(1,1,f,e),nxz )
               volbl = volbl + vlsum(bm1 (1,1,1,e),nxyz)
            endif
         enddo
         enddo
         srfbl = glsum(srfbl,1)  ! Sum over all processors
         volbl = glsum(volbl,1)
         delta = volbl / srfbl   ! Avg thickness of b.l. elements
c        delta = 0.02            ! 1/2 separation of cylinders
         call rone (h1,n)
         call rzero(h2,n)

c         do e=1,nelv
c         do f=1,nface
c         cbc(f,e,1)=cbc_usr(f,e)
c         enddo
c         enddo

         call cheap_dist(d,1,'mv ')

c         do e=1,nelv
c         do f=1,nface
c         if ((cbc(f,e,1).eq.'mv ').and.(.not.ifstrs)) then
c         cbc(f,e,1)='v  '
c         endif
c         enddo
c         enddo

         if (nid.eq.0) write(6,*) "delta: ",delta
         deltap1 = 1.0*delta  ! Protected b.l. thickness
         deltap2 = 2.0*delta

         do i=1,n
            arg1   = -(d(i)/deltap1)**2
            arg2   = -(d(i)/deltap2)**2
            h1(i)  = h1(i) + 1000.0*exp(arg1) + 10.0*exp(arg2)
         enddo

         call rone(mask,n)
         do e=1,nelv
         do f=1,nface
           zero = 0.
           one  = 1.
         if(cbc_usr(f,e).eq.'W  ')call facev(mask,e,f,zero,nx1,ny1,nz1)
         if(cbc_usr(f,e).eq.'W1 ')call facev(mask,e,f,one,nx1,ny1,nz1)    !! for sides to be moved.
         if(cbc_usr(f,e).eq.'v  ')call facev(mask,e,f,zero,nx1,ny1,nz1)
         if(cbc_usr(f,e).eq.'mv ')call facev(mask,e,f,zero,nx1,ny1,nz1)
         if(cbc_usr(f,e).eq.'O  ')call facev(mask,e,f,zero,nx1,ny1,nz1)
         enddo
         enddo
         call dsop(mask,'*  ',nx1,ny1,nz1)    ! dsop mask
         call opzero(wx,wy,wz)
c        call outpost(w1mask,w2mask,w3mask,mask,mask,'msk')
c        call exitti('QUIT MASK$',nx1)

c change W1 to W
         do e=1,nelv
         do f=1,nface
         if (cbc(f,e,1).eq.'W1 ') then
         cbc(f,e,1)='W  '
         endif
         enddo
         enddo
      endif

cc      if (nid.eq.0) write(6,*) "delta: ",delta

      do e=1,nelv
      do f=1,nface
         if (cbc_usr(f,e).eq.'mv ') then
           call facec(wx,umeshx,e,f,nx1,ny1,nz1,nelv)
           call facec(wy,umeshy,e,f,nx1,ny1,nz1,nelv)
           call facec(wz,umeshz,e,f,nx1,ny1,nz1,nelv)
         endif
      enddo
      enddo
      tol = -1.e-3

      pmax=glamax(wx,n)
      if (nid.eq.0) write(6,*) "wx: ",pmax

      utx_usr=glamax(umeshx,n)
      uty_usr=glamax(umeshy,n)
      utz_usr=glamax(umeshz,n)

      if (nid.eq.0) write(6,*) "utx_usr: ",utx_usr
      if (nid.eq.0) write(6,*) "uty_usr: ",uty_usr
      if (nid.eq.0) write(6,*) "utz_usr: ",utz_usr

      if (utx_usr.gt.1e-8)
     & call laplaceh('mshx',wx,h1,h2,mask,vmult,1,tol,
     & 500,apprx,napprx)
      if (uty_usr.gt.1e-8)
     & call laplaceh('mshy',wy,h1,h2,mask,vmult,1,tol,
     & 500,appry,nappry)
      if (utz_usr.gt.1e-8)
     & call laplaceh('mshz',wz,h1,h2,mask,vmult,1,tol,
     & 500,apprz,napprz)

      ifxyo=.true.
      if (mod(istep,iostep).eq.0) call outpost(wx,wy,wz,h1,h1,'mvv')
      if (mod(istep,iostep).eq.0) then
      call outpost(umeshx,umeshy,umeshz,h1,h1,'mv2')
      endif

      return
      end
c-----------------------------------------------------------------------
      subroutine laplaceh
     $     (name,u,h1,h2,mask,mult,ifld,tli,maxi,approx,napprox)
c
c     Solve Laplace's equation, with projection onto previous solutions.
c
c     Boundary condition strategy:
c
c     u = u0 + ub
c
c        u0 = 0 on Dirichlet boundaries
c        ub = u on Dirichlet boundaries
c
c        _
c        A ( u0 + ub ) = 0
c
c        _            _
c        A  u0  =   - A ub
c
c        _             _
c       MAM u0  =   -M A ub,    M is the mask
c
c                      _
c        A  u0  =   -M A ub ,  Helmholtz solve with SPD matrix A
c
c        u = u0+ub
c
      include 'SIZE'
      include 'TOTAL'
      include 'CTIMER'
c
      character*4 name
      real u(1),h1(1),h2(1),mask(1),mult(1),approx (1)
      integer   napprox(1)

      parameter (lt=lx1*ly1*lz1*lelt)
      common /scruz/ r (lt),ub(lt)

      logical ifstdh
      character*4  cname
      character*6  name6

      logical ifwt,ifvec

      call chcopy(cname,name,4)
      call capit (cname,4)

      call blank (name6,6)
      call chcopy(name6,name,4)
      ifwt  = .true.
      ifvec = .false.
      isd   = 1
      imsh  = 1
      nel   = nelfld(ifld)

      n = nx1*ny1*nz1*nel

      call copy (ub,u,n)             ! ub = u on boundary
      call dsavg(ub)                 ! Make certain ub is in H1
                                     !     _
      call axhelm (r,ub,h1,h2,1,1)   ! r = A*ub

      do i=1,n                       !        _
         r(i)=-r(i)*mask(i)          ! r = -M*A*ub
      enddo

      call dssum  (r,nx1,ny1,nz1)    ! dssum rhs

      call project1
     $    (r,n,approx,napprox,h1,h2,mask,mult,ifwt,ifvec,name6)

      tol = abs(tli)
      p22=param(22)
      param(22)=abs(tol)
      if (nel.eq.nelv) then
        call hmhzpf (name,u,r,h1,h2,mask,mult,imsh,tol,maxi,isd,binvm1)
      else
        call hmhzpf (name,u,r,h1,h2,mask,mult,imsh,tol,maxi,isd,bintm1)
      endif
      param(22)=p22

      call project2
     $     (u,n,approx,napprox,h1,h2,mask,mult,ifwt,ifvec,name6)

      call add2(u,ub,n)

      return
      end
C=======================================================================

c automatically added by makenek
      subroutine usrdat0() 

      return
      end

c automatically added by makenek
      subroutine usrsetvert(glo_num,nel,nx,ny,nz) ! to modify glo_num
      integer*8 glo_num(1)

      return
      end
