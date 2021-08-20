CROSS_IMAGE_NAME   := skycoin/golang-cross-builder
IMAGE_NAME         := skycoin/golang-cross
GHCR_IMAGE_NAME    ?= ghcr.io/alexadhy/golang-cross
GO_VERSION         ?= 1.16.7
TAG_VERSION        := v$(GO_VERSION)
GORELEASER_VERSION := 0.159.0
GORELEASER_SHA     := 68ce200307ab83f62cc98feb74bfc642110dbe63ab1b51f172190a797cf2627c
OSX_SDK            := MacOSX11.3.sdk
OSX_SDK_SUM        := cd4f08a75577145b8f05245a2975f7c81401d75e9535dcffbb879ee1deefcbf4
OSX_VERSION_MIN    := 10.14
OSX_CROSS_COMMIT   := 5771a847950abefed9a37e2d16ee10e0dd90c641
DEBIAN_FRONTEND    := noninteractive

SUBIMAGES = linux-amd64

PUSHIMAGES = base \
	$(SUBIMAGES)

subimages: $(patsubst %, golang-cross-%,$(SUBIMAGES))

.PHONY: golang-cross-base
golang-cross-base:
	@echo "building $(IMAGE_NAME):$(TAG_VERSION)-$(@:golang-cross-%=%)"
	docker build -t $(IMAGE_NAME):$(TAG_VERSION)-$(@:golang-cross-%=%) \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg GORELEASER_VERSION=$(GORELEASER_VERSION) \
		--build-arg GORELEASER_SHA=$(GORELEASER_SHA) \
		-f Dockerfile.$(@:golang-cross-%=%) .
	docker tag $(IMAGE_NAME):$(TAG_VERSION)-$(@:golang-cross-%=%) $(GHCR_IMAGE_NAME):$(TAG_VERSION)-$(@:golang-cross-%=%)

.PHONY: golang-cross-%
golang-cross-%: golang-cross-base
	@echo "building $(IMAGE_NAME):$(TAG_VERSION)-$(@:golang-cross-%=%)"
	docker build -t $(IMAGE_NAME):$(TAG_VERSION)-$(@:golang-cross-%=%) \
		--build-arg GO_VERSION=$(GO_VERSION) \
		-f Dockerfile.$(@:golang-cross-%=%) .
	docker tag $(IMAGE_NAME):$(TAG_VERSION)-$(@:golang-cross-%=%) $(GHCR_IMAGE_NAME):$(TAG_VERSION)-$(@:golang-cross-%=%)

.PHONY: golang-cross
golang-cross: golang-cross-base
	@echo "building $(IMAGE_NAME):$(TAG_VERSION)"
	docker build -t $(IMAGE_NAME):$(TAG_VERSION) \
		--build-arg GO_VERSION=$(GO_VERSION) \
		--build-arg OSX_SDK=$(OSX_SDK) \
		--build-arg OSX_SDK_SUM=$(OSX_SDK_SUM) \
		--build-arg OSX_VERSION_MIN=$(OSX_VERSION_MIN) \
		--build-arg OSX_CROSS_COMMIT=$(OSX_CROSS_COMMIT) \
		--build-arg DEBIAN_FRONTEND=$(DEBIAN_FRONTEND) \
		-f Dockerfile.full .
	docker tag $(IMAGE_NAME):$(TAG_VERSION) $(GHCR_IMAGE_NAME):$(TAG_VERSION)

.PHONY: docker-push-%
docker-push-%:
	docker push $(IMAGE_NAME):$(TAG_VERSION)-$(@:docker-push-%=%)
	docker push $(GHCR_IMAGE_NAME):$(TAG_VERSION)-$(@:docker-push-%=%)

.PHONY: docker-push
docker-push: $(patsubst %, docker-push-%,$(PUSHIMAGES))
	docker push $(IMAGE_NAME):$(TAG_VERSION)
	docker push $(GHCR_IMAGE_NAME):$(TAG_VERSION)
